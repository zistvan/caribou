(1) Starting the Nodes
======================

### Initializing data structures, flushing memory contents

Multes can be used in two different modes (or a mix of these): replicated or node-local.
Regardless of the use, after programming the FPGA it needs to be reset (essentially a flush command to each FPGA). Furthermore, since by default each FPGA supports eight tenants, this has to be done for each tenant.

	for IP in $FPGAIP_0 $FPGAIP_1 $FPGAIP_2
	do	
		for TEN in `seq 0 7` do
			echo -n 'FFFF00FF01000000F00BA20000000000f00f00f00f00f00f' | xxd -r -p | nc $IP 288$TEN -q 2 			
		done
	done

The expected answer to this request is (with the last 8B being the same as the middle 8B of the flush command above):

	FFFF 0100 0000 0000 F00B A200 0000 0000

Once this has been done, the FPGA is ready to serve get/put requests or to have the Zookeeper Atomic Broadcast subsystem configured.

### Initial replication config

If there is more than one FPGA, nodes need to be told that they will participate in the replication group and who the first leader is. This can be done with the code in the /src/ClusterManagement project running the CommandLineInterface class:
	
	CommandLineInterface $FPGAIP_0:2888;$FPGAIP_1:2888;$FPGAIP_2:2888

To add nodes later, run the same class with the original group as first argument, and the additional node as second argument:

	CommandLineInterface $FPGAIP_0:2888;$FPGAIP_1:2888;$FPGAIP_2:2888 $FPGAIP_new:2888	

For an overview of the commands that can be sent to the replication control logic (initialize peer, add or remove peers, and set leader), please use the Java code as a starting point.

(2) Sending Commands to the Nodes
=================================

Multes has two types of commands: node-local and replicated ones. 

Replicated commands are:
* Set 
* [Delete]

Node local commands are:
* Flush
* Get
* ConditionalGet
* [Scan]
* SetLocal
* DeleteLocal
* ConfigTenantLimits

Note: the operations in square brackets have buggy/incomplete behavior and are not to be used until further code updates.

## Request format definitions

### KVS Operations

All requests sent to Multes start with the magic number 0xFFFF and have to be zero-padded to 8byte multiples.

From the client's perspective the only important operation is "replicated set" that will replicate the given key and value to all nodes. (Other operations and their code can be found in zk_control_CentralSM.vhdl.)

These operations are formatted as follows:

	FFFFxxCCPPPP0000
	EEEEEEEEEEEEEEEE
	KKKKKKKKKKKKKKKK
	LLLLVVVVVVVVVVVV
	...
	VVVVVVVVVVVVVVVV

Legend: 

* x [1B] = reserved to encode node id
* C [1B] = opcode: 0x01 for replicated SET, node-local command code: 0x00 for GET, 0x1F for SET-LOCAL, 0x2F for DELETE-LOCAL, 0xFF for FLUSH, 0x40 for GET-CONDITIONAL
* P [2B] = payload (key + value) size in 64bit words. E.g. 4=4*64bit
* E [8B] = reserved to encode epoch, zxid
* K [64B] = key (can be only 64bit long)
* L [2B] = length of value (including these two bytes) in bytes -- maximum is 1KB by default, but can be changed in code
* V [variable] = value (if no value is needed for the operation, stop at K)

In-code examples of these operations can be found in the Go client in /src/

#### Conditional gets

The FPGA can be confugured with one or multiple filters that can execute a condition on the value when retrieved. If the condition holds, the value is returned in full, otherwise an empty response is sent to the client. This allows for pushing down filtering operations into the storage.

A conditional get operation consists of a key and instead of a value, a bitvector that configures *all* processing elements on the node. These can be of various types, but the default ones are "byte comparisons". The bit vector is a concatenation of the configuration vector of each element, padded so that it is a multiple of 8Bs, with a maximum size of 64Bs.

The "byte comparators" have the following configuration bits:
	
	Bit 0-11: Offset in the value (counting the 2Bs for length as well!)
	Bit 12-15: Comparison function (0=equal, 1=smaller, 2=larger, 3=notequal).
	Bit 16-47 (4 Bytes): Constant to compare to.

If there are 8 comparators, up to 8 x 48B can be provided in the configuration vector. An all zero bitvector disables the comparator, and internally the bitvector is padded with zeros.

### Tenant shares config

The Token Buckets can be configured for each tenant separately by piggybacking the information on a regular packet (e.g. on a GET). The tenant choice is implicit depending on what to which port the request is sent to.
The information is to be encoded in bytes 8-16 of the request, in the following way:

	Bytes 8-9: 0xBBBB -- magic number
	Byte   10: 0x00 or 0x01 -- choice of the first or second token bucket
	Byte   11: 0x01 to 0xFF -- how many tokens to add on each "tick"
	Byte   12: 0x01 to 0xFF -- how many clock cycles @156MHz for one "tick"
	Byte13-14: 2 bytes for maximum burst size as number of 8B words (beware of reverse byte order on the network link)
	Byte15-16: 0x0000 padding

For more information on where each token bucker is located, please see the paper Multes paper that describes the architecture.


(3) Go Client
=============

We provide a go client for testing purposes (code needs cleanup). 
To populate run:

	./client -host "$LEADER_IP:2880" -populate -time 120 (-replicate) (-flush)

To do some mixed ops (50% writes) for 10 seconds

	./client -host "$LEADER_IP:2880" -setp 0.5 -time 10

...

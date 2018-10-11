# Multes

Multes [1] is the multi-tenant incarnation of Caribou [2]. It implements **smart distributed storage** built with FPGAs that can efficiently be shared by a large number of tenants. Each node stores key-value pairs in main memory and exposes a simple interface over TCP/IP [3] that software clients can connect to. 

It is **smart** because it is possible to offload filtering into the storage nodes. The nodes can also perform scans on the data. In this design filtering is a combination of regular expression matching and predicate evaluation. Different types of processing can, however, easily be added to the processing pipeline. 

It is **distributed** because it runs on multiple FPGAs that replicate the data using a leader-based consensus protocol [4] that is both low latency and high throughput.

It is **storage** because it stores key-value pairs in a Cuckoo hash table and implements slab-based memory allocation. The current design uses DRAM to store data, as an exploration for solutions that will work well with the emerging non-volatile memory technologies. 

#### Referenced articles:

[1]Providing Multi-tenant Services with FPGAs: Case Study on a Key-Value Store. Zs. István, G. Alonso, A. Singla. 28th International Conference on Field Programmable Logic and Applications (FPL'18), Dublin, Ireland . https://zistvan.github.io/doc/multes-fpl18.pdf

[2] Caribou: Intelligent Distributed Storage. Zs. Istvan, D. Sidler, G. Alonso. In VLDB 2017, Munich, Germany. https://people.inf.ethz.ch/zistvan/doc/vldb17-caribou.pdf

[3] Low-Latency TCP/IP Stack for Data Center Applications. D. Sidler, Zs. Istvan, G. Alonso. 26th International Conference on Field Programmable Logic and Applications (FPL'16), Lausanne, Switzerland, September 2016.  http://davidsidler.ch/files/fpl16-lowlatencytcpip.pdf

[4] Consensus in a Box: Inexpensive Coordination in Hardware. Zs. Istvan, D. Sidler, G. Alonso, M. Vukolic. 13th USENIX Symposium on Networked Systems Design and Implementation (NSDI '16), March 2016. https://people.inf.ethz.ch/zistvan/doc/nsdi16-istvan-rev1.pdf
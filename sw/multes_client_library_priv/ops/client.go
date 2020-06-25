package ops

import "multes_client_library_priv/internal"

// Client is an entity that can establish the connection to an K/V store
// and interact with it
type Client struct {
	address string
	conn    internal.ConnectedSender
}

// NewClient initializes a new client type with the given address
func NewClient(addr string) *Client {
	return &Client{address: addr, conn: &internal.CaribouConnection{Timeout: internal.DefTimeout}}
}

// NewTestClient initializes a client that communicates with a Memcached
// instance for test purposes
func NewTestClient(addr string) *Client {
	return &Client{address: addr, conn: &internal.MemcachedConnection{}}
}

// Connect establishes a connection to the defined address of the server
func (c *Client) Connect() error {
	return c.conn.Connect(c.address)
}

// Init initializes the K/V store by flushing all it's data
func (c *Client) Init() error {
	return c.conn.Send(internal.NewInitOp(), &internal.EmptyResHandler{})
}

// Disconnect closes the connection to the server
func (c *Client) Disconnect() {
	c.conn.Close()
}

func (c Client) clone() *Client {

	switch c.conn.(type) {
	case *internal.CaribouConnection:
		return &Client{address: c.address, conn: &internal.CaribouConnection{Timeout: internal.DefTimeout}}
	case *internal.MemcachedConnection:
		return &Client{address: c.address, conn: &internal.MemcachedConnection{}}
	default:
		return nil
	}
}

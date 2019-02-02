defmodule CacheBodyReader do
  def read_body(conn, opts \\ nil) do
    IO.inspect("CacheBodyReader")
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
    {:ok, body, conn}
  end
end

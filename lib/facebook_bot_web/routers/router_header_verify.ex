defmodule FacebookBotWeb.Router_Header_Verify_Signature do
  @moduledoc """
  Plug Plugin for verify header signature of facebook request
  """

  import Plug.Conn

  @fb_app_secret Application.fetch_env!(:facebook_bot, :fb_app_secret)

  def init(opts), do: opts

  def call(conn, _opts) do
    signature = get_req_header(conn, "x-hub-signature") |> Enum.at(0)

    if signature do
      elements = String.split(signature, "=")
      method = Enum.at(elements, 0)
      signatureHash = Enum.at(elements, 1)
      {:ok, body, conn} = read_body(conn)

      expectedHash =
        :crypto.hmac(:sha, @fb_app_secret, conn.assigns.raw_body)
        |> Base.encode16()
        |> String.downcase()

      if signatureHash != expectedHash do
        IO.puts("Couldn't validate the request signature.")

        conn
        |> halt()
      else
        conn
      end
    else
      IO.puts("Couldn't validate the signature.")

      conn
      |> halt()
    end
  end
end

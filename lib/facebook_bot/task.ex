defmodule FacebookBot.Task do
  @moduledoc """
  fetch schedule from lol esport and notify to subcribers
  """

  alias FacebookBotWeb.LolHandler
  alias FacebookBotWeb.FacebookHandler

  def fetch_data() do
    FacebookHandler.notify_schedule()
  end
end

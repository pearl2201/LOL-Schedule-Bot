defmodule FacebookBotWeb.SubcribeModelTest do
  @moduledoc """
  Test Subcribe_Manager
  """
  use FacebookBotWeb.ConnCase, async: true

  alias FacebookBot.FaccebookBot.Subcribe_Manager

  setup do
    {:ok, subcribe} = Subcribe_Manager.insert("1", "2", "3")
    :ok
  end

  test "test_insert", state do
    {:ok, subcribe} = Subcribe_Manager.insert("1", "2", "4")
    assert(subcribe.user == "1")
    assert(subcribe.league == "2")
    assert(subcribe.team == "4")
  end

  test "test_query", state do
    subcribe = Subcribe_Manager.query("2", "3")
    assert(subcribe.league == "2")
    assert(subcribe.team == "3")
    assert(nil == Subcribe_Manager.query("2", "4"))
  end

  test "test_delete", state do
    {:ok, subcribe} = Subcribe_Manager.delete("1", "2", "3")
    assert(subcribe.user == "1")
    assert(subcribe.league == "2")
    assert(subcribe.team == "3")
    assert(Subcribe_Manager.delete("1", "2", "4") == false)
  end
end

defmodule LoopsWithFriends.PageControllerTest do
  use LoopsWithFriends.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Elm.App.fullscreen"
  end
end

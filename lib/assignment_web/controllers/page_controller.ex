defmodule AssignmentWeb.PageController do
  use AssignmentWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

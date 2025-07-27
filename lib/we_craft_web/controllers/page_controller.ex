defmodule WeCraftWeb.PageController do
  use WeCraftWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

defmodule Value8BetsWeb.ErrorJSONTest do
  use Value8BetsWeb.ConnCase, async: true

  test "renders 404" do
    assert Value8BetsWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert Value8BetsWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end

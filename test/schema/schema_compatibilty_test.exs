defmodule Polyn.SchemaCompatabilityTest do
  use ExUnit.Case, async: true

  alias Polyn.SchemaCompatability

  test "compatible if no old" do
    new = %{
      "type" => "object",
      "required" => ["name"],
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    }

    assert :ok = SchemaCompatability.check!(nil, new)
  end

  test "compatible if exact same" do
    old = %{
      "type" => "object",
      "required" => ["name"],
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    }

    new = %{
      "type" => "object",
      "required" => ["name"],
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    }

    assert :ok = SchemaCompatability.check!(old, new)
  end

  test "compatible if new optional field is added" do
    old = %{
      "type" => "object",
      "required" => ["name"],
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    }

    new = %{
      "type" => "object",
      "required" => ["name"],
      "properties" => %{
        "name" => %{"type" => "string"},
        "birthday" => %{"type" => "date"}
      }
    }

    assert :ok = SchemaCompatability.check!(old, new)
  end

  test "compatible if new nested optional field is added that has required" do
    old = %{
      "type" => "object",
      "required" => ["name"],
      "properties" => %{
        "name" => %{"type" => "string"}
      }
    }

    new = %{
      "type" => "object",
      "required" => ["name"],
      "properties" => %{
        "name" => %{"type" => "string"},
        "address" => %{"type" => "object", "required" => ["zip"]}
      }
    }

    assert :ok = SchemaCompatability.check!(old, new)
  end

  test "compatible if required field order changes" do
    old = %{"type" => "object", "required" => ["name", "birthday"]}

    new = %{"type" => "object", "required" => ["birthday", "name"]}

    :ok = SchemaCompatability.check!(old, new)
  end

  test "incompatible if existing field becomes required" do
    old = %{"type" => "object"}

    new = %{"type" => "object", "required" => ["name"]}

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~
             "You added required fields of [\"name\"] at path \"/required\". " <>
               "Adding new required fields is not backwards-compatibile"
  end

  test "incompatible if new required field is added" do
    old = %{"type" => "object", "required" => ["name"]}

    new = %{"type" => "object", "required" => ["name", "birthday"]}

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~
             "You added required fields of [\"birthday\"] at path \"/required/1\". " <>
               "Adding new required fields is not backwards-compatibile"
  end

  test "incompatible if required removed" do
    old = %{"type" => "object", "required" => ["name"]}

    new = %{"type" => "object"}

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~
             "You removed required fields of [\"name\"] at path \"/required\". " <>
               "Making fields that were previously required, optional is not backwards-compatibile"
  end

  test "incompatible if required no longer required" do
    old = %{"type" => "object", "required" => ["name", "birthday"]}

    new = %{"type" => "object", "required" => ["name"]}

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~
             "You removed required fields of [\"birthday\"] at path \"/required/1\". " <>
               "Making fields that were previously required, optional is not backwards-compatibile"
  end

  test "incompatible if new required field is added nested" do
    old = %{
      "type" => "object",
      "properties" => %{
        "address" => %{
          "type" => "object",
          "required" => ["line_one"]
        }
      }
    }

    new = %{
      "type" => "object",
      "properties" => %{
        "address" => %{
          "type" => "object",
          "required" => ["line_one", "zip"]
        }
      }
    }

    %{message: message} =
      assert_raise(Polyn.SchemaException, fn ->
        SchemaCompatability.check!(old, new)
      end)

    assert message =~
             "You added required fields of [\"zip\"] at path \"/properties/address/required/1\". " <>
               "Adding new required fields is not backwards-compatibile"
  end

  test "multiple type changes" do
    old = %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"},
        "birthday" => %{"type" => "date"}
      }
    }

    new = %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "integer"},
        "birthday" => %{"type" => "datetime"}
      }
    }

    assert_raise(Polyn.SchemaException, fn ->
      SchemaCompatability.check!(old, new)
    end)
  end
end

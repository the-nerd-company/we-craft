defmodule WeCraft.Pages.Infrastructure.Ecto.BlockRepositoryEctoTest do
  @moduledoc """
  Tests for the BlockRepositoryEcto module.
  """
  use WeCraft.DataCase

  alias WeCraft.Pages.Block
  alias WeCraft.Pages.Infrastructure.Ecto.BlockRepositoryEcto
  alias WeCraft.PagesFixtures
  alias WeCraft.Repo

  describe "create_block/1" do
    test "creates a block with valid attributes" do
      page = PagesFixtures.page_fixture()

      attrs = %{
        type: :text,
        content: %{"text" => "This is a test block"},
        position: 1,
        page_id: page.id
      }

      assert {:ok, %Block{} = block} = BlockRepositoryEcto.create_block(attrs)
      assert block.type == :text
      assert block.content == %{"text" => "This is a test block"}
      assert block.position == 1
      assert block.page_id == page.id
      assert is_nil(block.parent_id)
    end

    test "creates a block with parent block" do
      parent_block = PagesFixtures.block_fixture()

      attrs = %{
        type: :text,
        content: %{"text" => "Child block content"},
        position: 2,
        page_id: parent_block.page_id,
        parent_id: parent_block.id
      }

      assert {:ok, %Block{} = block} = BlockRepositoryEcto.create_block(attrs)
      assert block.parent_id == parent_block.id
      assert block.page_id == parent_block.page_id
    end

    test "creates different block types" do
      page = PagesFixtures.page_fixture()

      # Test heading block
      heading_attrs = %{
        type: :heading,
        content: %{"text" => "Chapter Title", "level" => 2},
        position: 1,
        page_id: page.id
      }

      assert {:ok, %Block{} = heading} = BlockRepositoryEcto.create_block(heading_attrs)
      assert heading.type == :heading
      assert heading.content["level"] == 2

      # Test checklist block
      checklist_attrs = %{
        type: :checklist,
        content: %{"items" => [%{"text" => "Task 1", "checked" => false}]},
        position: 2,
        page_id: page.id
      }

      assert {:ok, %Block{} = checklist} = BlockRepositoryEcto.create_block(checklist_attrs)
      assert checklist.type == :checklist
      assert is_list(checklist.content["items"])
    end

    test "returns error with invalid attributes" do
      attrs = %{type: nil, content: nil, position: nil}

      assert {:error, %Ecto.Changeset{}} = BlockRepositoryEcto.create_block(attrs)
    end

    test "returns error with missing required fields" do
      attrs = %{type: :text}

      assert {:error, %Ecto.Changeset{}} = BlockRepositoryEcto.create_block(attrs)
    end

    test "returns error with invalid block type" do
      page = PagesFixtures.page_fixture()

      attrs = %{
        type: :invalid_type,
        content: %{"text" => "Test"},
        position: 1,
        page_id: page.id
      }

      assert {:error, %Ecto.Changeset{}} = BlockRepositoryEcto.create_block(attrs)
    end

    test "returns error with invalid page_id" do
      attrs = %{
        type: :text,
        content: %{"text" => "Test"},
        position: 1,
        # Non-existent page
        page_id: 99_999
      }

      # This should raise a constraint error since we don't have foreign_key_constraint in changeset
      assert_raise Ecto.ConstraintError, fn ->
        BlockRepositoryEcto.create_block(attrs)
      end
    end
  end

  describe "update_block/2" do
    test "updates a block with valid attributes" do
      block =
        PagesFixtures.block_fixture(%{
          type: :text,
          content: %{"text" => "Original content"}
        })

      update_attrs = %{
        type: :heading,
        content: %{"text" => "Updated heading", "level" => 3}
      }

      assert {:ok, %Block{} = updated_block} =
               BlockRepositoryEcto.update_block(block, update_attrs)

      assert updated_block.type == :heading
      assert updated_block.content["text"] == "Updated heading"
      assert updated_block.content["level"] == 3
      assert updated_block.id == block.id
    end

    test "updates block position" do
      block = PagesFixtures.block_fixture(%{position: 1})

      update_attrs = %{position: 5}

      assert {:ok, %Block{} = updated_block} =
               BlockRepositoryEcto.update_block(block, update_attrs)

      assert updated_block.position == 5
    end

    test "updates block content only" do
      block =
        PagesFixtures.block_fixture(%{
          type: :text,
          content: %{"text" => "Original content"}
        })

      update_attrs = %{
        content: %{"text" => "Updated content", "style" => "bold"}
      }

      assert {:ok, %Block{} = updated_block} =
               BlockRepositoryEcto.update_block(block, update_attrs)

      assert updated_block.content["text"] == "Updated content"
      assert updated_block.content["style"] == "bold"
      # Type should remain unchanged
      assert updated_block.type == block.type
    end

    test "returns error with invalid attributes" do
      block = PagesFixtures.block_fixture()

      update_attrs = %{type: nil}

      assert {:error, %Ecto.Changeset{}} = BlockRepositoryEcto.update_block(block, update_attrs)
    end

    test "returns error with invalid block type" do
      block = PagesFixtures.block_fixture()

      update_attrs = %{type: :invalid_type}

      assert {:error, %Ecto.Changeset{}} = BlockRepositoryEcto.update_block(block, update_attrs)
    end
  end

  describe "delete_block/1" do
    test "deletes a block successfully" do
      block = PagesFixtures.block_fixture()

      assert {:ok, %Block{}} = BlockRepositoryEcto.delete_block(block)
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Block, block.id) end
    end

    test "deletes a block with children" do
      parent_block = PagesFixtures.block_fixture()
      child_block = PagesFixtures.block_with_parent_fixture(%{parent_block: parent_block})

      assert {:ok, %Block{}} = BlockRepositoryEcto.delete_block(parent_block)

      # Parent should be deleted
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Block, parent_block.id) end

      # Child should also be deleted due to cascade
      assert_raise Ecto.NoResultsError, fn -> Repo.get!(Block, child_block.id) end
    end

    test "returns error when block is already deleted" do
      block = PagesFixtures.block_fixture()

      # Delete the block successfully first
      assert {:ok, %Block{}} = BlockRepositoryEcto.delete_block(block)

      # Try to delete the same block again - should raise StaleEntryError
      assert_raise Ecto.StaleEntryError, fn ->
        BlockRepositoryEcto.delete_block(block)
      end
    end
  end

  describe "block relationships" do
    test "block belongs to page" do
      page = PagesFixtures.page_fixture()
      block = PagesFixtures.block_fixture(%{page: page})

      block_with_page = Repo.preload(block, :page)
      assert block_with_page.page.id == page.id
    end

    test "block can have parent block" do
      parent_block = PagesFixtures.block_fixture()
      child_block = PagesFixtures.block_with_parent_fixture(%{parent_block: parent_block})

      child_with_parent = Repo.preload(child_block, :parent_block)
      assert child_with_parent.parent_block.id == parent_block.id
    end

    test "block can have children blocks" do
      parent_block = PagesFixtures.block_fixture()
      child1 = PagesFixtures.block_with_parent_fixture(%{parent_block: parent_block})
      child2 = PagesFixtures.block_with_parent_fixture(%{parent_block: parent_block})

      parent_with_children = Repo.preload(parent_block, :children)
      child_ids = Enum.map(parent_with_children.children, & &1.id)
      assert child1.id in child_ids
      assert child2.id in child_ids
      assert length(parent_with_children.children) == 2
    end
  end
end

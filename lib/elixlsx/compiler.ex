defmodule Elixlsx.Compiler do
  @moduledoc false

  alias Elixlsx.Compiler.WorkbookCompInfo
  alias Elixlsx.Compiler.SheetCompInfo
  alias Elixlsx.Compiler.CellStyleDB
  alias Elixlsx.Compiler.StringDB
  alias Elixlsx.XML
  alias Elixlsx.Sheet

  @doc ~S"""
  Accepts a list of Sheets and the next free relationship ID.

  Returns a tuple containing a list of SheetCompInfo's and the next free
  relationship ID.
  """
  @spec make_sheet_info(nonempty_list(Sheet.t()), non_neg_integer) ::
          {list(SheetCompInfo.t()), non_neg_integer}
  def make_sheet_info(sheets, init_rid) do
    # fold helper. aggregator holds {list(sheet_comp_infos), sheetidx, rid}.
    add_sheet = fn _, {sci, idx, rid} ->
      {[SheetCompInfo.make(idx, rid) | sci], idx + 1, rid + 1}
    end

    # TODO probably better to use a zip [1..] |> map instead of fold[l|r]/reverse
    {sheet_comp_infos, _, next_rid} = List.foldl(sheets, {[], 1, init_rid}, add_sheet)
    {Enum.reverse(sheet_comp_infos), next_rid}
  end

  def compinfo_cell_pass_value(wci, value) do
    if is_binary(value) and XML.valid?(value) do
      update_in(wci.stringdb, &StringDB.register_string(&1, value))
    else
      wci
    end
  end

  def compinfo_cell_pass_style(wci, props) do
    update_in(
      wci.cellstyledb,
      &CellStyleDB.register_style(
        &1,
        Elixlsx.Style.CellStyle.from_props(props)
      )
    )
  end

  @spec compinfo_cell_pass(WorkbookCompInfo.t(), any) :: WorkbookCompInfo.t()
  def compinfo_cell_pass(wci, cell) do
    if is_list(cell) do
      wci
      |> compinfo_cell_pass_value(hd(cell))
      |> compinfo_cell_pass_style(tl(cell))
    else
      # no style information attached in this cell
      compinfo_cell_pass_value(wci, cell)
    end
  end

  @spec compinfo_from_rows(WorkbookCompInfo.t(), list(list(any()))) :: WorkbookCompInfo.t()
  def compinfo_from_rows(wci, rows) do
    List.foldl(rows, wci, fn cols, wci ->
      List.foldl(cols, wci, fn cell, wci ->
        compinfo_cell_pass(wci, cell)
      end)
    end)
  end

  @spec compinfo_from_sheets(WorkbookCompInfo.t(), list(Sheet.t())) :: WorkbookCompInfo.t()
  def compinfo_from_sheets(wci, sheets) do
    List.foldl(sheets, wci, fn sheet, wci ->
      compinfo_from_rows(wci, sheet.rows)
    end)
  end

  @first_free_rid 2
  def make_workbook_comp_info(workbook) do
    {sci, next_rid} = make_sheet_info(workbook.sheets, @first_free_rid)

    %WorkbookCompInfo{
      sheet_info: sci,
      next_free_xl_rid: next_rid
    }
    |> compinfo_from_sheets(workbook.sheets)
    |> CellStyleDB.register_all()
  end
end

defmodule MerkleTreeRoot.Process do
  @moduledoc """
    This module is responsible for processing merkle root transactions contained inside of a file
  """

  # Typespecs
  @type file_path :: String.t()
  @type transactions :: list()

  # Supervisor
  @default_file_path "lib/transactions.txt"

  require Logger

  @doc """
    Starts processing the file. It receives the file path as a first argument, if none is provided
    the function will use the default path (lib/transactions.txt).

    It chunks,formats and hashes the transactions before returning them.

    My goal was to achieve the best performance, because of that I've tried several approaches and 
    combinations to find out which one brought me the highest speed. I discovered that using Flow 
    only on the hashing process was the best option. Because of that, I've combinated Flow with
    Stream and Task, resulting on an average of 0.061579 to complete the processing task. 
    (16384 lines of transactions)
  """
  @spec start(file_path()) :: list()
  def start(file_path \\ @default_file_path) when is_binary(file_path) do
    file_path
    # Read the file
    |> File.stream!()
    |> chunk_transactions()
    |> format_transactions()
    |> hash_transactions()
  end

  @doc """
    Returns the amount of time the `start/1` function took to complete
  """
  @spec benchmark(file_path()) :: none()
  def benchmark(file_path \\ @default_file_path) do
    Logger.info("Queue started")

    processing_speed =
      :timer.tc(fn ->
        start(file_path)
      end)
      # Parses the processing speed
      |> elem(0)
      |> Kernel./(1_000_000)

    Logger.info("Queue finished in #{processing_speed}")
  end

  # Chunks the transactions
  @spec chunk_transactions(transactions()) :: list()
  defp chunk_transactions(transactions), do: Stream.chunk_every(transactions, 2)

  @spec format_transactions(transactions()) :: list()
  defp format_transactions(transactions) do
    # Start an async task
    Task.async(fn ->
      transactions
      |> Enum.map(fn pair ->
        # Iterate over all of the transactions
        pair
        |> Enum.map(fn single_transaction ->
          single_transaction
          # Format the transactions by removing the \n (line break)
          |> String.replace("\n", "")
        end)
      end)
    end)
    # Await and complete the task
    |> Task.await()
  end

  @spec hash_transactions(transactions()) :: list()
  defp hash_transactions(transactions) do
    transactions
    # Parse the transactions into a Flow struct
    |> Flow.from_enumerable()
    |> Flow.partition()
    # Hash all the transactions
    |> Flow.map(&hash_branch/1)
    |> Enum.to_list()
  end

  @spec hash_branch(list(String.t())) :: String.t()
  defp hash_branch([single_node]) do
    :crypto.hash(:sha256, Base.decode16!(single_node <> single_node, case: :mixed))
    |> Base.encode16(case: :lower)
  end

  @spec hash_branch(list(String.t())) :: String.t()
  defp hash_branch([left_node, right_node]) do
    :crypto.hash(:sha256, Base.decode16!(left_node <> right_node, case: :mixed))
    |> Base.encode16(case: :lower)
  end
end

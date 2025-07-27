# Create S3 bucket if it doesn't exist
bucket_name = "uploads"

# How I setup bucket policy in production
# ExAws.S3.put_bucket_policy("wecraft-production", Jason.encode!(%{
#   "Version" => "2012-10-17",
#   "Statement" => [
#     %{
#       "Sid" => "PublicRead",
#       "Effect" => "Allow",
#       "Principal" => "*",
#       "Action" => [
#         "s3:GetObject",
#         "s3:PutObject"
#       ],
#       "Resource" => [
#         "arn:aws:s3:::wecraft-production/*",
#         "arn:aws:s3:::wecraft-production"
#       ]
#     }
#   ]
# }))|> ExAws.request()

# Convert policy to JSON string
bucket_policy = Jason.encode!(%{
  "Version" => "2012-10-17",
  "Statement" => [
    %{
      "Sid" => "PublicRead",
      "Effect" => "Allow",
      "Principal" => "*",
      "Action" => [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource" => [
        "arn:aws:s3:::#{bucket_name}/*",
        "arn:aws:s3:::#{bucket_name}"
      ]
    }
  ]
})

# Ensure bucket exists
case ExAws.S3.head_bucket(bucket_name) |> ExAws.request() do
  {:ok, _} ->
    IO.puts("Bucket #{bucket_name} already exists")

  {:error, _} ->
    IO.puts("Creating bucket: #{bucket_name}")
    # Create bucket
    case ExAws.S3.put_bucket(bucket_name, "us-east-1") |> ExAws.request() do
      {:ok, _} -> IO.puts("Bucket created successfully")
      {:error, {:http_error, 409, _}} -> IO.puts("Bucket already exists")
      {:error, error} -> raise "Failed to create bucket: #{inspect(error)}"
    end
end

# Wait a moment for bucket creation to propagate
Process.sleep(1000)

# Set bucket policy and ACL
# Set bucket policy
case ExAws.S3.put_bucket_policy(bucket_name, bucket_policy) |> ExAws.request() do
  {:ok, _} ->
    IO.puts("Bucket policy set successfully")
  {:error, {:http_error, 409, _}} ->
    IO.puts("Bucket policy already exists")
  {:error, error} ->
    IO.puts("Warning: Failed to set bucket policy: #{inspect(error)}")
end

# Set bucket ACL
case ExAws.S3.put_bucket_acl(bucket_name, %{acl: :public_read}) |> ExAws.request() do
  {:ok, _} ->
    IO.puts("Bucket ACL set successfully")
  {:error, {:http_error, 409, _}} ->
    IO.puts("Bucket ACL already set")
  {:error, error} ->
    IO.puts("Warning: Failed to set bucket ACL: #{inspect(error)}")
end

# Verify bucket exists and is accessible
case ExAws.S3.head_bucket(bucket_name) |> ExAws.request() do
  {:ok, _} ->
    IO.puts("Bucket #{bucket_name} is ready")
  {:error, error} ->
    IO.puts("Warning: Could not verify bucket accessibility: #{inspect(error)}")
end

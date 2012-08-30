module Elasticity

  class NoBucketError < StandardError; end
  class NoDirectoryError < StandardError; end

  class SyncToS3

    attr_reader :access_key
    attr_reader :secret_key
    attr_reader :bucket_name

    def initialize(bucket, access=nil, secret=nil)
      @access_key = get_access_key(access)
      @secret_key = get_secret_key(secret)
      @bucket_name = bucket
    end

    def sync(local, remote)
      raise_unless bucket, NoBucketError, "Bucket '#@bucket_name' does not exist"
      raise_unless File.directory?(local), NoDirectoryError, "Directory '#{local}' does not exist or is not a directory"
      sync_dir(local, remote)
    end

    private

    def sync_dir(local, remote)
      Dir.glob(File.join([local, '*'])).each do |entry|
        if File.directory?(entry)
          sync_dir(entry, [remote, File.basename(entry)].join('/'))
        else
          sync_file(entry, remote)
        end
      end
    end

    def sync_file(file_name, remote_dir)
      remote_dir = remote_dir.gsub(/^(\/)/, '')
      remote_path = (remote_dir.empty?) ? (File.basename(file_name)) : [remote_dir, File.basename(file_name)].join('/')
      metadata = bucket.files.head(remote_path)
      return if metadata && metadata.etag == Digest::MD5.file(file_name).to_s

      bucket.files.create({
        :key => remote_path,
        :body => File.open(file_name),
        :public => false
      })
    end

    def bucket
      index = s3.directories.index { |d| d.key == @bucket_name }
      @bucket ||= index ? s3.directories[index] : nil
    end

    def s3
      @connection ||= Fog::Storage.new({
        :provider => 'AWS',
        :aws_access_key_id => @access_key,
        :aws_secret_access_key => @secret_key
      })
    end

    def get_access_key(access)
      return access if access
      return ENV['AWS_ACCESS_KEY_ID'] if ENV['AWS_ACCESS_KEY_ID']
      raise MissingKeyError, 'Please provide an access key or set AWS_ACCESS_KEY_ID.'
    end

    def get_secret_key(secret)
      return secret if secret
      return ENV['AWS_SECRET_ACCESS_KEY'] if ENV['AWS_SECRET_ACCESS_KEY']
      raise MissingKeyError, 'Please provide a secret key or set AWS_SECRET_ACCESS_KEY.'
    end

  end

end
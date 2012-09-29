module Elasticity

  class NoBucketError < StandardError; end
  class NoDirectoryError < StandardError; end
  class NoFileError < StandardError; end

  class SyncToS3

    attr_reader :access_key
    attr_reader :secret_key
    attr_reader :bucket_name
    attr_reader :region

    def initialize(bucket, access=nil, secret=nil, region=nil)
      @access_key = get_access_key(access)
      @secret_key = get_secret_key(secret)
      @bucket_name = bucket
      @region = region ||= 'us-east-1'
    end

    def sync(local, remote)
      warn "[DEPRECATION] 'sync' will be removed in the next release.  Please use 'sync_dir' instead."
      sync_dir(local, remote)
    end

    # Recursively sync the contents of directory 'dir_name' to 'remote_dir'
    def sync_dir(dir_name, remote_dir)
      raise NoDirectoryError, "Directory '#{dir_name}' does not exist or is not a directory" unless File.directory?(dir_name)
      Dir.glob(File.join([dir_name, '*'])).each do |entry|
        if File.directory?(entry)
          sync_dir(entry, [remote_dir, File.basename(entry)].join('/'))
        else
          sync_file(entry, remote_dir)
        end
      end
    end

    def sync_file(file_name, remote_dir)
      raise NoFileError, "File '#{file_name}' does not exist" unless File.exists?(file_name)
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

    private

    def bucket
      @bucket ||= s3.directories.find { |d| d.key == @bucket_name }
      @bucket ||= s3.directories.create(:key => @bucket_name)
    end

    def s3
      @connection ||= Fog::Storage.new({
        :provider => 'AWS',
        :region => @region,
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
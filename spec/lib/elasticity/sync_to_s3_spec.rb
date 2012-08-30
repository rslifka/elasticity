describe Elasticity::SyncToS3 do

  include FakeFS::SpecHelpers
  Fog.mock!

  let(:bucket_name) { 'TEST_BUCKET' }
  let(:sync_to_s3) { Elasticity::SyncToS3.new(bucket_name, '_', '_') }
  let(:s3) { Fog::Storage.new({:provider => 'AWS', :aws_access_key_id => '', :aws_secret_access_key => ''}) }

  before do
    Fog::Mock.reset
    sync_to_s3.stub(:s3).and_return(s3)
  end

  describe '#initialize' do

    describe 'basic assignment' do

      it 'should set the proper values' do
        sync = Elasticity::SyncToS3.new('bucket', 'access', 'secret')
        sync.access_key.should == 'access'
        sync.secret_key.should == 'secret'
        sync.bucket_name.should == 'bucket'
      end

    end

    context 'when access and secret keys are nil' do

      let(:both_keys_nil) { Elasticity::SyncToS3.new('_', nil, nil) }
      let(:both_keys_missing) { Elasticity::SyncToS3.new('_') }

      before do
        ENV.stub(:[]).with('AWS_ACCESS_KEY_ID').and_return(access_key)
        ENV.stub(:[]).with('AWS_SECRET_ACCESS_KEY').and_return(secret_key)
      end

      context 'when environment variables are present' do
        let(:access_key) { 'ENV_ACCESS' }
        let(:secret_key) { 'ENV_SECRET' }
        it 'should assign them to the keys' do
          both_keys_nil.access_key.should == 'ENV_ACCESS'
          both_keys_nil.secret_key.should == 'ENV_SECRET'

          both_keys_missing.access_key.should == 'ENV_ACCESS'
          both_keys_missing.secret_key.should == 'ENV_SECRET'
        end
      end

      context 'when environment variables are not present' do

        context 'when access is not set' do
          let(:access_key) { nil }
          let(:secret_key) { '_' }
          it 'should raise an error' do
            expect {
              both_keys_nil # Trigger instantiation
            }.to raise_error(Elasticity::MissingKeyError, 'Please provide an access key or set AWS_ACCESS_KEY_ID.')
          end
        end

        context 'when secret is not set' do
          let(:access_key) { '_' }
          let(:secret_key) { nil }
          it 'should raise an error' do
            expect {
              both_keys_nil # Trigger instantiation
            }.to raise_error(Elasticity::MissingKeyError, 'Please provide a secret key or set AWS_SECRET_ACCESS_KEY.')
          end
        end

      end

    end

  end

  describe '#sync' do

    context 'when the bucket exists' do

      before do
        s3.directories.create(:key => bucket_name)
      end

      context 'when the local directory exists' do
        before do
          FileUtils.mkdir('GOOD_DIR')
        end
        it 'should sync that directory' do
          sync_to_s3.should_receive(:sync_dir).with('GOOD_DIR', 'REMOTE_DIR')
          sync_to_s3.sync('GOOD_DIR', 'REMOTE_DIR')
        end
      end

      context 'when the local directory does not exist' do
        it 'should raise an error' do
          expect {
            sync_to_s3.sync('BAD_DIR', '_')
          }.to raise_error(Elasticity::NoDirectoryError, "Directory 'BAD_DIR' does not exist or is not a directory")
        end
      end

      context 'when the local directory is not a directory' do
        before do
          FileUtils.touch('NOT_A_DIR')
        end
        it 'should raise an error' do
          expect {
            sync_to_s3.sync('NOT_A_DIR', '_')
          }.to raise_error(Elasticity::NoDirectoryError, "Directory 'NOT_A_DIR' does not exist or is not a directory")
        end
      end

    end

    context 'when the bucket does not exist' do
      let(:bucket_name) { 'BAD_BUCKET' }
      it 'should raise an error' do
        expect {
          sync_to_s3.sync('_', '_')
        }.to raise_error(Elasticity::NoBucketError, "Bucket 'BAD_BUCKET' does not exist")
      end
    end

  end

  describe '#sync_dir' do

    before do
      s3.directories.create(:key => bucket_name)

      FileUtils.makedirs(File.join(%w(local_dir sub_dir_1)))
      FileUtils.makedirs(File.join(%w(local_dir sub_dir_2)))

      FileUtils.touch(File.join(%w(local_dir file_1)))
      FileUtils.touch(File.join(%w(local_dir file_2)))
      FileUtils.touch(File.join(%w(local_dir sub_dir_1 file_3)))
      FileUtils.touch(File.join(%w(local_dir sub_dir_1 file_4)))
      FileUtils.touch(File.join(%w(local_dir sub_dir_2 file_5)))
      FileUtils.touch(File.join(%w(local_dir sub_dir_2 file_6)))
    end

    it 'should recursively sync all files and directories' do
      sync_to_s3.send(:sync_dir, 'local_dir', 'remote_dir')

      %w(
        remote_dir/file_1
        remote_dir/file_2
        remote_dir/sub_dir_1/file_3
        remote_dir/sub_dir_1/file_4
        remote_dir/sub_dir_2/file_5
        remote_dir/sub_dir_2/file_6
      ).each do |key|
        s3.directories[0].files.map(&:key).should include(key)
      end
    end

  end

  describe '#sync_file' do

    let(:local_dir) { '/tmp' }
    let(:file_name) { 'test.out' }
    let(:full_path) { File.join([local_dir, file_name]) }
    let(:remote_dir) { 'job/assets' }
    let(:remote_path) { "#{remote_dir}/#{file_name}"}
    let(:file_data) { 'Some test content' }

    before do
      s3.directories.create(:key => bucket_name)
      FileUtils.makedirs(local_dir)
      File.open(full_path, 'w') {|f| f.write(file_data) }
    end

    it 'should write the specified file into the remote directory' do
      sync_to_s3.send(:sync_file, full_path, remote_dir)
      s3.directories[0].files.head(remote_path).should_not be_nil
    end

    it 'should write the contents of the file' do
      sync_to_s3.send(:sync_file, full_path, remote_dir)
      s3.directories[0].files.head(remote_path).body.should == file_data
    end

    it 'should write the remote file without public access' do
      sync_to_s3.send(:sync_file, full_path, remote_dir)
      s3.directories[0].files.head(remote_path).public_url.should be_nil
    end

    it 'should not write identical content' do
      sync_to_s3.send(:sync_file, full_path, remote_dir)
      last_modified = s3.directories[0].files.head(remote_path).last_modified
      Timecop.travel(Time.now + 60)
      sync_to_s3.send(:sync_file, full_path, remote_dir)
      s3.directories[0].files.head(remote_path).last_modified.should == last_modified
    end

    context 'when remote dir is a corner case value' do
      before do
        sync_to_s3.send(:sync_file, full_path, remote_dir)
      end

      context 'when remote dir is empty' do
        let(:remote_dir) {''}
        it 'should place files in the root without a bunk empty folder name' do
          s3.directories[0].files.head(file_name).should_not be_nil
        end
      end

      context 'when remote dir is /' do
        let(:remote_dir) {'/'}
        it 'should place files in the root without a bunk empty folder name' do
          s3.directories[0].files.head(file_name).should_not be_nil
        end
      end

      context 'when remote dir starts with a /' do
        let(:remote_dir) {'/starts_with_slash'}
        it 'should place files in the root without a bunk empty folder name' do
          s3.directories[0].files.head('starts_with_slash/test.out').should_not be_nil
        end
      end
    end

  end

  describe '#s3' do
    let(:connection_test) { Elasticity::SyncToS3.new('_', 'access', 'secret') }
    it 'should connect to S3 using the specified credentials' do
      Fog::Storage.should_receive(:new).with({
        :provider => 'AWS',
        :aws_access_key_id => 'access',
        :aws_secret_access_key => 'secret'
      }).and_return('GOOD_CONNECTION')
      connection_test.send(:s3).should == 'GOOD_CONNECTION'
    end
  end

end
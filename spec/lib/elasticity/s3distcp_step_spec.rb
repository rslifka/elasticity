describe Elasticity::S3DistCpStep do

  it 'should be a CustomJarStep' do
    expect(subject).to be_a(Elasticity::CustomJarStep)
  end

  it 'should set the appropriate default fields' do
    expect(subject.name).to eql('Elasticity S3DistCp Step')
    expect(subject.jar).to eql('/usr/share/aws/emr/s3-dist-cp/lib/s3-dist-cp.jar')
  end

  context 'legacy' do

    subject { described_class.new(true) }

    it 'sets the correct JAR location' do
      expect(subject.jar).to eql('/home/hadoop/lib/emr-s3distcp-1.0.jar')
    end
  end

end

describe Elasticity::S3DistCpStep do

  it 'should be a CustomJarStep' do
    expect(subject).to be_a(Elasticity::CustomJarStep)
  end

  it 'should set the appropriate default fields' do
    expect(subject.name).to eql('Elasticity S3DistCp Step')
    expect(subject.jar).to eql('/home/hadoop/lib/emr-s3distcp-1.0.jar')
  end

end
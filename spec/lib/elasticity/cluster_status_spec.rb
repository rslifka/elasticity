describe Elasticity::ClusterStatus do

  let(:cluster_state) { 'TERMINATED' }
  let(:aws_cluster_status) do
    <<-JSON
      {
        "Cluster": {
          "Applications": [
            {
              "Name": "hadoop",
              "Version": "1.0.3"
            }
          ],
          "AutoTerminate": true,
          "Configurations": [

          ],
          "Ec2InstanceAttributes": {
            "Ec2AvailabilityZone": "us-east-1a",
            "EmrManagedMasterSecurityGroup": "sg-b7de0adf",
            "EmrManagedSlaveSecurityGroup": "sg-89de0ae1"
          },
          "Id": "j-3T0PHNUXCY7SX",
          "MasterPublicDnsName": "ec2-54-81-173-103.compute-1.amazonaws.com",
          "Name": "Elasticity Job Flow",
          "NormalizedInstanceHours": 2,
          "RequestedAmiVersion": "latest",
          "RunningAmiVersion": "2.4.2",
          "Status": {
            "State": "#{cluster_state}",
            "StateChangeReason": {
              "Code": "ALL_STEPS_COMPLETED",
              "Message": "Steps completed"
            },
            "Timeline": {
              "CreationDateTime": 1436788464.415,
              "EndDateTime": 1436791032.097,
              "ReadyDateTime": 1436788842.195
            }
          },
          "Tags": [
            {
              "Key": "key",
              "Value": "value"
            }
          ],
          "TerminationProtected": false,
          "VisibleToAllUsers": false
        }
      }
    JSON
  end

  subject do
    Elasticity::ClusterStatus.from_aws_data(JSON.parse(aws_cluster_status))
  end

  describe '.from_aws_data' do
    it 'should hydate properly' do
      expect(subject.name).to eql('Elasticity Job Flow')
      expect(subject.cluster_id).to eql('j-3T0PHNUXCY7SX')
      expect(subject.state).to eql('TERMINATED')
      expect(subject.created_at).to eql(Time.at(1436788464.415))
      expect(subject.ready_at).to eql(Time.at(1436788842.195))
      expect(subject.ended_at).to eql(Time.at(1436791032.097))
      expect(subject.last_state_change_reason).to eql('ALL_STEPS_COMPLETED')
      expect(subject.master_public_dns_name).to eql('ec2-54-81-173-103.compute-1.amazonaws.com')
      expect(subject.normalized_instance_hours).to eql(2)
    end
  end

  describe '#active?' do

    context 'when the jobflow status is terminal' do
      %w{COMPLETED TERMINATED FAILED _}.each do |status|
        context "when the jobflow is #{status}" do
          let(:cluster_state) {status}
          it 'is not active' do
            expect(subject.active?).to be false
          end
        end
      end
    end

    context 'when the jobflow status is not terminal' do
      %w{RUNNING STARTING BOOTSTRAPPING WAITING SHUTTING_DOWN}.each do |status|
        context "when the jobflow is #{status}" do
          let(:cluster_state) {status}
          it 'is active' do
            expect(subject.active?).to be true
          end
        end
      end
    end

  end

end
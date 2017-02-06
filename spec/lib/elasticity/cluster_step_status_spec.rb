describe Elasticity::ClusterStepStatus do

  let(:timeline) do
    <<-JSON
      {
        "CreationDateTime": 1436788464.416,
        "StartDateTime": 1436788841.237,
        "EndDateTime": 1436790944.162
      }
    JSON
  end

  let(:aws_cluster_steps) do
    <<-JSON
      {
          "Steps": [
              {
                  "ActionOnFailure": "TERMINATE_CLUSTER",
                  "Config": {
                      "Args": [
                          "36",
                          "3",
                          "0"
                      ],
                      "Jar": "s3n://cxar-ato-team/snowplow-hosted-elasticmapreduce/samples/cloudburst/cloudburst.jar",
                      "MainClass" : "MAIN_CLASS",
                      "Properties": {
                          "Key1" : "Value1",
                          "Key2" : "Value2"
                      }
                  },
                  "Id": "s-OYPPAC4XPPUC",
                  "Name": "Elasticity Custom Jar Step",
                  "Status": {
                      "State": "COMPLETED",
                      "StateChangeReason": {
                        "Code": "ALL_STEPS_COMPLETED",
                        "Message": "Steps completed"
                      },
                      "Timeline": #{timeline}
                  }
              }
          ]
      }
    JSON
  end

  describe '.from_aws_list_data' do
    let(:cluster_step_statuses) { Elasticity::ClusterStepStatus.from_aws_list_data(JSON.parse(aws_cluster_steps)) }

    it 'should extract the proper number of steps' do
      expect(cluster_step_statuses.length).to eql(1)
    end

    it 'should hydate properly' do
      status = cluster_step_statuses[0]
      expect(status.action_on_failure).to eql('TERMINATE_CLUSTER')
      expect(status.args).to eql(['36', '3', '0',])
      expect(status.jar).to eql('s3n://cxar-ato-team/snowplow-hosted-elasticmapreduce/samples/cloudburst/cloudburst.jar')
      expect(status.main_class).to eql('MAIN_CLASS')
      expect(status.step_id).to eql('s-OYPPAC4XPPUC')
      expect(status.properties).to eql({'Key1' => 'Value1', 'Key2' => 'Value2'})
      expect(status.name).to eql('Elasticity Custom Jar Step')
      expect(status.state).to eql('COMPLETED')
      expect(status.state_change_reason).to eql('ALL_STEPS_COMPLETED')
      expect(status.state_change_reason_message).to eql('Steps completed')
      expect(status.created_at).to eql(Time.at(1436788464.416))
      expect(status.started_at).to eql(Time.at(1436788841.237))
      expect(status.ended_at).to eql(Time.at(1436790944.162))
    end

    context 'newly created step that hasn\'t started yet' do
      let(:timeline) do
        <<-JSON
          {
            "CreationDateTime": 1436788464.416
          }
        JSON
      end

      it 'sets started_at and ended_at to nil' do
        status = cluster_step_statuses[0]
        expect(status.started_at).not_to be
        expect(status.ended_at).not_to be
      end
    end
  end

  describe '.installed_steps' do
    let(:installed_cluster_step_statuses) do
      step_names = Elasticity::JobFlowStep.steps_requiring_installation.map { |s| s.aws_installation_step_name }
      step_names.map { |name| build(:cluster_step_status, :name => name) }
    end

    it 'should return a list of steps that are installed' do
      expect(Elasticity::ClusterStepStatus.installed_steps(installed_cluster_step_statuses)).to match_array([
            Elasticity::PigStep, Elasticity::HiveStep
          ])
    end
  end

end

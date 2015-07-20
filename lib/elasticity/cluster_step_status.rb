module Elasticity

  class ClusterStepStatus

    attr_accessor :action_on_failure
    attr_accessor :args
    attr_accessor :jar
    attr_accessor :main_class
    attr_accessor :properties
    attr_accessor :step_id
    attr_accessor :name
    attr_accessor :state
    attr_accessor :state_change_reason
    attr_accessor :state_change_reason_message
    attr_accessor :created_at
    attr_accessor :started_at
    attr_accessor :ended_at

    # Constructed from http://docs.aws.amazon.com/ElasticMapReduce/latest/API/API_ListSteps.html
    def self.from_aws_list_data(cluster_step_data)
      cluster_step_data['Steps'].map do |s|
        ClusterStepStatus.new.tap do |c|
          c.action_on_failure = s['ActionOnFailure']
          c.args = s['Config']['Args']
          c.jar = s['Config']['Jar']
          c.main_class = s['Config']['MainClass']
          c.properties = s['Config']['Properties']
          c.step_id = s['Id']
          c.name = s['Name']
          c.state = s['Status']['State']
          c.state_change_reason = s['Status']['StateChangeReason']['Code']
          c.state_change_reason_message = s['Status']['StateChangeReason']['Message']
          c.created_at = Time.at(s['Status']['Timeline']['CreationDateTime'])
          c.started_at = s['Status']['Timeline']['StartDateTime'] ? Time.at(s['Status']['Timeline']['StartDateTime']) : nil
          c.ended_at   = s['Status']['Timeline']['EndDateTime'] ? Time.at(s['Status']['Timeline']['EndDateTime']) : nil
        end
      end
    end

    def self.installed_steps(cluster_step_statuses)
      step_names = cluster_step_statuses.map(&:name)
      installed_steps = []
      Elasticity::JobFlowStep.steps_requiring_installation.each do |step|
        installed_steps << step if step_names.include?(step.aws_installation_step_name)
      end
      installed_steps
    end

  end

end

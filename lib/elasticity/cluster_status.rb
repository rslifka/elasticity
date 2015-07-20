module Elasticity

  class ClusterStatus

    attr_accessor :name
    attr_accessor :cluster_id
    attr_accessor :state
    attr_accessor :created_at
    attr_accessor :ready_at
    attr_accessor :ended_at
    attr_accessor :last_state_change_reason
    attr_accessor :master_public_dns_name
    attr_accessor :normalized_instance_hours

    # ClusterStatus is created via the results of the DescribeCluster API call
    def self.from_aws_data(cluster_data)
      cluster_data = cluster_data['Cluster']
      ClusterStatus.new.tap do |c|
        c.name = cluster_data['Name']
        c.cluster_id = cluster_data['Id']
        c.state = cluster_data['Status']['State']
        c.created_at = Time.at(cluster_data['Status']['Timeline']['CreationDateTime'])
        c.ready_at = cluster_data['Status']['Timeline']['ReadyDateTime'] ? Time.at(cluster_data['Status']['Timeline']['ReadyDateTime']) : nil
        c.ended_at = cluster_data['Status']['Timeline']['EndDateTime'] ? Time.at(cluster_data['Status']['Timeline']['EndDateTime']) : nil
        c.last_state_change_reason = cluster_data['Status']['StateChangeReason']['Code']
        c.master_public_dns_name = cluster_data['MasterPublicDnsName']
        c.normalized_instance_hours = cluster_data['NormalizedInstanceHours']
      end
    end

    # http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/ProcessingCycle.html
    def active?
      %w{RUNNING STARTING BOOTSTRAPPING WAITING SHUTTING_DOWN}.include?(@state)
    end

  end

end

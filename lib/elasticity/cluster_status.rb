module Elasticity

  class ClusterStatus

    attr_reader :name
    attr_reader :cluster_id
    attr_reader :state
    attr_reader :created_at
    attr_reader :ready_at
    attr_reader :ended_at
    attr_reader :last_state_change_reason
    attr_reader :master_public_dns_name
    attr_reader :normalized_instance_hours

    # ClusterStatus is created via the results of the DescribeCluster API call
    def initialize(cluster_data)
      cluster_data = cluster_data['Cluster']

      @name = cluster_data['Name']
      @cluster_id = cluster_data['Id']
      @state = cluster_data['Status']['State']
      @created_at = Time.at(cluster_data['Status']['Timeline']['CreationDateTime'])
      @ready_at = Time.at(cluster_data['Status']['Timeline']['ReadyDateTime'])
      @ended_at = Time.at(cluster_data['Status']['Timeline']['EndDateTime'])
      @last_state_change_reason = cluster_data['Status']['StateChangeReason']['Code']
      @master_public_dns_name = cluster_data['MasterPublicDnsName']
      @normalized_instance_hours = cluster_data['NormalizedInstanceHours']
    end

    # http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/ProcessingCycle.html
    def active?
      %w{RUNNING STARTING BOOTSTRAPPING WAITING SHUTTING_DOWN}.include?(@state)
    end

  end

end
FactoryGirl.define do
  factory :cluster_status, class: Elasticity::ClusterStatus do
    cluster_id 'CLUSTER_ID'
    state 'TERMINATED'
    created_at Time.at(1436788464.415)
    ready_at Time.at(1436788842.195)
    ended_at Time.at(1436791032.097)
    last_state_change_reason 'ALL_STEPS_COMPLETED'
    master_public_dns_name 'ec2-54-81-173-103.compute-1.amazonaws.com'
    normalized_instance_hours 999
  end
end

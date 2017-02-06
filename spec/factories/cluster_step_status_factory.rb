FactoryGirl.define do
  factory :cluster_step_status, class: Elasticity::ClusterStepStatus do 
    action_on_failure 'TERMINATE_CLUSTER'
    args ['36', '3', '0',]
    jar 's3n://cxar-ato-team/snowplow-hosted-elasticmapreduce/samples/cloudburst/cloudburst.jar'
    main_class 'MAIN_CLASS'
    step_id 's-OYPPAC4XPPUC'
    properties 'Key1' => 'Value1', 'Key2' => 'Value2'
    name 'Elasticity Custom Jar Step'
    state 'COMPLETED'
    state_change_reason 'ALL_STEPS_COMPLETED'
    state_change_reason_message 'Steps completed'
    created_at Time.at(1436788464.416)
    started_at Time.at(1436788841.237)
    ended_at Time.at(1436790944.162)
  end
end

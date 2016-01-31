module Elasticity
  class S3DistCpStep < CustomJarStep
    def initialize(legacy = false)
      path = '/usr/share/aws/emr/s3-dist-cp/lib/s3-dist-cp.jar'
      path = '/home/hadoop/lib/emr-s3distcp-1.0.jar' if legacy # For AMI version < 4
      super(path)
      @name = 'Elasticity S3DistCp Step'
    end
  end
end

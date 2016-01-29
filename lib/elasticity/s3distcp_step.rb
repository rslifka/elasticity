module Elasticity

  class S3DistCpStep < CustomJarStep

    def initialize(legacy = true)
      path = if legacy
      	# For AMI version < 4
      	'/home/hadoop/lib/emr-s3distcp-1.0.jar'
      else
      	# For AMI version >= 4
      	'/usr/share/aws/emr/s3-dist-cp/lib/s3-dist-cp.jar'
      end
      super(path)
      @name = 'Elasticity S3DistCp Step'
    end

  end

end
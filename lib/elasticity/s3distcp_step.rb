module Elasticity

  class S3DistCpStep < CustomJarStep

    def initialize
      super('/home/hadoop/lib/emr-s3distcp-1.0.jar')
      @name = 'Elasticity S3DistCp Step'
    end

  end

end
begin
  require 's3'
rescue LoadError
  #
  # There is no 's3' gem in Gmefile
  #
  #puts "There is no 's3' gem in Gemfile."
end

begin
  require 'right_aws'
rescue LoadError
  #
  # There is no 'right_aws' in Gemfile
  #
  #puts "There is no 'right_aws' gem in Gemfile."
end

if defined?(S3)
  #
  # Using 's3' gem an Amazon S3 interface
  #
  #puts "Using \'s3\' gem as Amazon S3 interface."
  def HerokuMongoBackup::s3_connect(bucket, key, secret)
    service = S3::Service.new(:access_key_id     => key,
                              :secret_access_key => secret)
    bucket  = service.buckets.find(bucket)
    return bucket
  end
  def HerokuMongoBackup::s3_upload(bucket, filename)
    object = bucket.objects.build("backups/#{filename}")
    object.content = open(filename)
    object.save
  end
  def HerokuMongoBackup::s3_download(bucket, filename)
    object  = bucket.objects.find("backups/#{filename}")
    content = object.content(reload=true)

    puts "Backup file:"
    puts "  name: #{filename}"
    puts "  type: #{object.content_type}"
    puts "  size: #{content.size} bytes"
    puts "\n"

    return content
  end


elsif defined?(RightAws)

  #
  # Using 'aws/s3' gem as Amazon S3 interface
  #
  #puts "Using \'aws/s3\' gem as Amazon S3 interface."
  def HerokuMongoBackup::s3_connect(bucket, key, secret)
    service = RightAws::S3.new(key, secret, :server => 's3-us-east-1.amazonaws.com')
    bucket = service.bucket(bucket, false, nil, :location => 'us-east-1')
    return bucket
  end
  def HerokuMongoBackup::s3_upload(bucket, filename)
    bucket.put("backups/#{filename}", open(filename))
  end
  def HerokuMongoBackup::s3_download(bucket, filename)
    content = bucket.get("backups/#{filename}")
    return content
  end


else
  begin
    require 'aws/s3'
  rescue LoadError
    #
    # There is no 'aws/s3' in Gemfile
    #
    #puts "There is no 'aws/s3' gem in Gemfile."
  end

  if defined?(AWS)
    #
    # Using 'aws/s3' gem as Amazon S3 interface
    #
    #puts "Using \'aws/s3\' gem as Amazon S3 interface."
    def HerokuMongoBackup::s3_connect(bucket, key, secret)
      AWS::S3::Base.establish_connection!(:access_key_id     => key,
                                          :secret_access_key => secret)
      return bucket
    end
    def HerokuMongoBackup::s3_upload(bucket, filename)
      AWS::S3::S3Object.store("backups/#{filename}", open(filename), bucket)
    end
    def HerokuMongoBackup::s3_download(bucket, filename)
      content = AWS::S3::S3Object.value("backups/#{filename}", bucket)
      return content
    end
  else
    logging = Logger.new(STDOUT)
    logging.error "heroku-mongo-backup: Please include 's3' or 'aws/s3' gem in applications Gemfile."
  end
end


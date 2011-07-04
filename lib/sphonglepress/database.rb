module Sphonglepress
  class Database
    class << self
      def drop(config)
        db = config["db"][::Sphonglepress::ENV_MODE]
        cmd = "echo \"drop database \\`#{db["database"]}\\`\" | mysql #{db_opts_no_db(CONFIG)}"
        puts cmd
        `#{cmd}`
      end
      
      def create(config)
        db = config["db"][::Sphonglepress::ENV_MODE]
        cmd = "echo \"create database \\`#{db["database"]}\\`\" | mysql #{db_opts_no_db(CONFIG)}"
        puts cmd
        `#{cmd}`
        
      end
      
      def db_opts(config)
        db = config["db"][::Sphonglepress::ENV_MODE]
        db_opts_no_db(config) << db["database"]
      end
      
      def db_opts_no_db(config)
        db = config["db"][::Sphonglepress::ENV_MODE]
         "-u #{db["username"]} " << (db["password"] ? "-p #{db["password"]} " : " ")
        
      end
    end
  end    
end
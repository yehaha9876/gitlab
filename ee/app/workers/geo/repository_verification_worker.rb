# Look through the projects table for projects updated in the last 24 hours
# and schedule a job to recalculate the repositories checksum. This job
# is triggered once a day at midnight.
module Geo
  class RepositoryVerificationWorker
    include ApplicationWorker
    include CronjobQueue

    def perform
    end
  end
end

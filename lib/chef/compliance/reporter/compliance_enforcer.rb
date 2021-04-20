class Chef
  module Compliance
    module Reporter
      class AuditEnforcer
        class ControlFailure < StandardError; end

        def send_report(report)
          report.fetch(:profiles, []).each do |profile|
            profile.fetch(:controls, []).each do |control|
              control.fetch(:results, []).each do |result|
                raise ControlFailure, "Audit #{control[:id]} has failed. Aborting #{ChefUtils::Dist::Infra::CLIENT} run." if result[:status] == "failed"
              end
            end
          end
          true
        end

        def validate_config!
          true
        end
      end
    end
  end
end

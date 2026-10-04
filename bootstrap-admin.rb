# frozen_string_literal: true
#
# Creates the first Discourse administrator from environment variables, mirroring the
# steps of upstream's interactive `rake admin:create`. Run by entrypoint.sh through
# `rails runner`, once, after the boot-time migration has finished.

email = ENV["ADMIN_EMAIL"].to_s.strip.downcase
password = ENV["ADMIN_PASSWORD"].to_s
username = ENV["ADMIN_USERNAME"].to_s.strip

if email.empty? || password.empty?
  puts "[railway] ADMIN_EMAIL / ADMIN_PASSWORD are not both set — nothing to do"
  exit 0
end

# Ids below 1 are Discourse's own system accounts, which are already admins.
if User.where(admin: true).where("id > 0").exists?
  puts "[railway] an administrator already exists — leaving it alone"
  exit 0
end

admin = User.find_by_email(email)
if admin.nil?
  admin = User.new
  admin.email = email
  admin.username = UserNameSuggester.suggest(username.presence || email)
end

admin.password = password
admin.active = true
admin.approved = true
admin.approved_at ||= Time.zone.now
admin.approved_by_id ||= Discourse::SYSTEM_USER_ID
admin.save!

admin.grant_admin!
admin.change_trust_level!(1) if admin.trust_level < 1
admin.email_tokens.update_all(confirmed: true)
admin.activate

# The shipped notification_email is noreply@discourse.example.com, which makes every
# outgoing message look forged. Point it at this deployment's own hostname, but only
# while it is still that default, so an operator's own value is never overwritten.
if SiteSetting.notification_email.to_s.end_with?("discourse.example.com")
  SiteSetting.notification_email = "noreply@#{Discourse.current_hostname}"
end

puts "[railway] administrator #{admin.username} <#{admin.email}> is ready"

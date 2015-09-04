require 'uri'

Given /^the only hosts in APT sources are "([^"]*)"$/ do |hosts_str|
  next if @skip_steps_while_restoring_background
  hosts = hosts_str.split(',')
  @vm.file_content("/etc/apt/sources.list /etc/apt/sources.list.d/*").chomp.each_line { |line|
    next if ! line.start_with? "deb"
    source_host = URI(line.split[1]).host
    if !hosts.include?(source_host)
      raise "Bad APT source '#{line}'"
    end
  }
end

When /^I update APT using apt-get$/ do
  next if @skip_steps_while_restoring_background
  Timeout::timeout(30*60) do
    @vm.execute_successfully("echo #{@sudo_password} | " +
                             "sudo -S apt-get update", :user => LIVE_USER)
  end
end

Then /^I should be able to install a package using apt-get$/ do
  next if @skip_steps_while_restoring_background
  package = "cowsay"
  Timeout::timeout(120) do
    @vm.execute_successfully("echo #{@sudo_password} | " +
                             "sudo -S apt-get install #{package}",
                             :user => LIVE_USER)
  end
  step "package \"#{package}\" is installed"
end

When /^I update APT using Synaptic$/ do
  next if @skip_steps_while_restoring_background
  # Upon start the interface will be frozen while Synaptic loads the
  # package list. Since the frozen GUI is so similar to the unfrozen
  # one there's no easy way to reliably wait for the latter. Hence we
  # spam reload until it's performed, which is easier to detect.
  try_for(60, :msg => "Failed to reload the package list in Synaptic") {
    @screen.type("r", Sikuli::KeyModifier.CTRL)
    @screen.find('SynapticReloadPrompt.png')
  }
  @screen.waitVanish('SynapticReloadPrompt.png', 30*60)
  # After this next image is displayed, the GUI should be responsive.
  @screen.wait('SynapticPackageList.png', 30)
end

Then /^I should be able to install a package using Synaptic$/ do
  next if @skip_steps_while_restoring_background
  package = "cowsay"
  @screen.type("f", Sikuli::KeyModifier.CTRL)  # Find key
  @screen.wait_and_click('SynapticSearch.png', 10)
  @screen.type(package + Sikuli::Key.ENTER)
  @screen.wait_and_click('SynapticCowsaySearchResult.png', 20)
  @screen.wait('SynapticCowsaySearchResultSelected.png', 20)
  @screen.type("i", Sikuli::KeyModifier.CTRL)    # Mark for installation
  @screen.wait('SynapticCowsayMarked.png', 10)
  @screen.wait_and_click('SynapticApply.png', 10)
  @screen.wait('SynapticApplyPrompt.png', 60)
  @screen.type("a", Sikuli::KeyModifier.ALT)     # Verify apply
  @screen.wait('SynapticChangesAppliedPrompt.png', 120)
  step "package \"#{package}\" is installed"
end

When /^I start Synaptic$/ do
  next if @skip_steps_while_restoring_background
  step 'I start "Synaptic" via the GNOME "System"/"Administration" applications menu'
  deal_with_polkit_prompt('SynapticPolicyKitAuthPrompt.png', @sudo_password)
end

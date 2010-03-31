package org.openqa.selenium.server.browserlaunchers;

import java.io.File;
import java.io.IOException;

import org.apache.commons.logging.Log;
import org.openqa.jetty.log.LogFactory;
import org.openqa.selenium.server.ApplicationRegistry;
import org.openqa.selenium.server.BrowserConfigurationOptions;
import org.openqa.selenium.server.RemoteControlConfiguration;
import org.openqa.selenium.server.browserlaunchers.locators.InternetExplorerLocator;

/**
 * Custom browser launcher that uses IE in HTA mode but sets up the proxy configuration to use
 * the Selenium server as a proxy.  This is necessary for handling invalid SSL certificats and
 * adding our own custom request headers.
 */
public class InternetExplorerMogoLauncher extends HTABrowserLauncher {

  private static final Log LOGGER = LogFactory.getLog(InternetExplorerMogoLauncher.class);

  private BrowserConfigurationOptions browserConfigurationOptions;
  private WindowsProxyManager wpm;
  private File customProxyPACDir;

  public InternetExplorerMogoLauncher(BrowserConfigurationOptions browserOptions, RemoteControlConfiguration configuration, String sessionId, String browserLaunchLocation) {
    super(browserOptions, configuration, sessionId, browserLaunchLocation);

    browserConfigurationOptions = browserOptions;
    wpm = new WindowsProxyManager(true, sessionId.concat("mogo"), configuration.getPortDriversShouldContact(),
        configuration.getPortDriversShouldContact());
  }

  @Override
  public void launchRemoteSession(String url) {
    try {
      setupSystemProxy();
    } catch (IOException e) {
      e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
    }

    customProxyPACDir = wpm.getCustomProxyPACDir();

    super.launchRemoteSession(url);
  }

  @Override
  public void close() {
    restoreSystemProxy();

    super.close();

    try {
      LauncherUtils.recursivelyDeleteDir(customProxyPACDir);
    } catch (RuntimeException e) {
      throw new RuntimeException("Couldn't delete custom IE " +
                                 "proxy directory, presumably because task kill failed; " +
                                 "see error log!", e);
    }
  }

  private void setupSystemProxy() throws IOException {
    wpm.backupRegistrySettings();
    changeRegistrySettings();
  }

  protected void changeRegistrySettings() throws IOException {
    wpm.changeRegistrySettings(browserConfigurationOptions.is("ensureCleanSession"),
        browserConfigurationOptions.is("avoidProxy"));
  }

  private void restoreSystemProxy() {
    wpm.restoreRegistrySettings(browserConfigurationOptions.is("ensureCleanSession"));
  }
}

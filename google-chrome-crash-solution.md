# Google-Chrome-Crash-Solution

Based on the detailed description and logs provided, it appears that Google Chrome is experiencing issues with PDF rendering on the Jenkins CI server, which seems to be related to environment variables and permissions.

# Possible root causes

## Chrome Version Compatibility:
a) The version that works: Google Chrome 127.0.6533.99
b) The version that is causing issues: Google Chrome 128.0.6613.119

This version mismatch might be contributing to the problem, but the primary cause seems to be related to file and directory permissions.

## Error Messages:
a) "Permission denied":
 ```sh
mkdir: cannot create directory '/srv/coachmeplus/releases/1.254.0_ra4e3482d/.local': Permission denied
```
This indicates that Chrome or the script doesn't have write access to this path. It's trying to create directories in the .local folder, which is located in a path where it doesn't have permissions.

## HOME Environment Variable Issue:
a) On Jenkins CI, the HOME environment variable is set to:

 ```sh
/srv/jenkins/workspace/virtuvia_training_CM-26407@tmp/phpunit_xmTNKaVXpnQ3/rustic-pdf-renderer-home-kSorfP
```
The developer's environment has a writable HOME path, while the Jenkins environment has a complex path structure that might not be writable.

## Chrome Crashpad Handler Error:
a) ``` chrome_crashpad_handler: --database is required ```
b) This error is common when Chrome's crash handling mechanism doesn't have the appropriate permissions to write to the ``` --crash-dumps-dir ``` directory.

## CPU Frequency Errors:
a) Jenkins is trying to access
 ``` /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ``` and ``` /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq ``` , which are not accessible or do not exist in your environment. 
 These errors suggest that Chrome's process is trying to read CPU frequency information but failing. However, these errors are more likely warnings and not the direct cause of the crash.

# Recommended Solutions 
## Set a Writable HOME Directory
The most immediate solution is to ensure that the HOME environment variable points to a writable location. The developer observed that setting the HOME environment variable resolved the issue locally. You can do the same on the Jenkins CI by modifying the Jenkins job configuration.
a) Jenkins Pipeline Modification:
   Edit your Jenkins job and add a build environment step to set the HOME environment variable to a writable directory, e.g., ``` /tmp/chrome_home ```

   Example modification in your Jenkins job script:
   ```sh
   export HOME=/tmp/chrome_home
   mkdir -p $HOME
   ```
b) Add Permissions for Required Directories
Ensure that the directories Chrome tries to access are writable:
```sh
sudo chmod -R 777 /srv/jenkins/workspace/virtuvia_training_CM-26407@tmp
```
Alternatively, Jenkins job can be run under a user that has the correct permissions to these directories.

c) Update Chrome Launch Parameters
   Modify how Chrome is launched within the pdf.phar script or Jenkins job configuration to include:
   i) ```--user-data-dir=/tmp/chrome_user_data ```: This option specifies a writable directory for Chrome's data.
   ii) ``` --disable-crash-reporter ```: This option disables the crash reporter, which avoids the chrome_crashpad_handler error.
   
   Example:
   ```sh
   /usr/bin/google-chrome --user-data-dir=/tmp/chrome_user_data --disable-crash-reporter <other-flags>
   ```
# These actions should address the "permission denied" errors, ensure Chrome has a proper environment to start, and resolve the PDF rendering issue.

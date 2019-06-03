
#force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Date=(Get-Date).ToString("yyyyMMdd")
$AccessToken=((Import-Csv ".\KeyValues.csv") | Where-Object -Property Key -EQ AccessToken).Value
$Url="https://api.github.com/user/repos?access_token=$AccessToken"
$Header=@{"Accept"="application/vnd.github.mercy-preview+json"}
$GitHubUsername=((Import-Csv ".\KeyValues.csv") | Where-Object -Property Key -EQ GitHubUsername).Value
$RepoBackupLocation=((Import-Csv ".\KeyValues.csv") | Where-Object -Property Key -EQ RepoBackupLocation).Value
$TopicsToInclude=@()
$TopicsToSkip=@()
$ReposToClone=@()
$Topic=""

#get topics to include - handle multiple topics
(Import-Csv ".\KeyValues.csv") | Where-Object -Property Key -EQ TopicToInclude | ForEach {
    $TopicsToInclude+=$_.Value
}

#get topics to skip - handle multiple topics
(Import-Csv ".\KeyValues.csv") | Where-Object -Property Key -EQ TopicToSkip | ForEach {
    $TopicsToSkip+=$_.Value
}

#if TopicsToInclude is populated get any repos with those topics, otherwise get all repos without a topic included in TopicsToSkip    
if ($TopicsToInclude.Count -gt 0) {
    (Invoke-RestMethod -Uri $Url -Headers $Header) | ForEach {
        $Name=$_.name
        $_.topics | ForEach {
            $Topic=$_
            $TopicsToInclude | ForEach {
                If ($_ -eq $Topic) {
                    $ReposToClone+=$Name
                }
            }
        }
    }
}
else {
    (Invoke-RestMethod -Uri $Url -Headers $Header) | ForEach {
        $Name=$_.name
        $Counter=0
        $_.topics | ForEach {
            $Topic=$_
            $TopicsToSkip | ForEach {
                if ($_ -eq $Topic) {
                    $Counter=$Counter+1
                }
                else {$Counter=$Counter+0}
            }
        }
        if ($Counter -eq 0) {
            $ReposToClone+=$Name
        }
    }
}

$ReposToClone | ForEach {
    git clone "https://{$GitHubUsername}:$AccessToken@github.com/$GitHubUsername/$_" "$RepoBackupLocation\$Date\$_"
}
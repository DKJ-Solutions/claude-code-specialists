<#
.SYNOPSIS
    Tests for scripts/lib/sibling-divergence-lib.ps1 -- the consumer-to-consumer comparison behind
    check-consumer-siblings.ps1 (#1869).

.DESCRIPTION
    WHAT IS ASSERTED HERE AND WHY THESE CASES. This lib decides what counts as duplicated work
    between two repos that are meant to run the same floor, and its failure modes are asymmetric in
    opposite directions:

      - A FALSE POSITIVE trains people to ignore the report. The expensive shape is not one wrong
        finding, it is a whole category of by-design difference leaking in -- the lenses, the seam --
        which on the real BWJ pair would be 26 unactionable findings sitting on top of 21 real ones.
        Cases 2 and 3 hold the exclusions.
      - A FALSE NEGATIVE is the defect the check exists to prevent, and the one that hides best: a
        capability duplicated under two filenames is invisible to every path comparison, which is
        exactly how market-domains.ps1 and market-urls.ps1 stayed unnoticed. Cases 6-9 hold that.

    THE PROPERTY THAT WOULD BREAK SILENTLY IS THE GROUPING BEING DECLARED. Inferring a sibling group
    is the change somebody will reach for the first time a manifest is added without the field, and
    it is wrong for a reason no error message would ever show: every consumer of this marketplace
    shares dkj-policy, so an inferred grouping puts a personal-life repo in a group with a Shopify
    store and reports it as missing a theme-archive mechanism. Case 4 is that assert, and case 5 is
    the other half -- a group of one is not a finding.

    NO NETWORK AND NO FIXTURE REPOS. Everything in this lib is a pure function over inventories that
    the entry point supplies, which is precisely why the comparison lives in a lib rather than inside
    the script: the reading is what needs a network, and the deciding is what needs testing. The
    inventories below are hand-built hashtables.

    THE FIXTURES ARE SYNTHETIC, DELIBERATELY. This repo is public and the consumers it compares are
    private, so a fixture carrying a real consumer's file content would publish it permanently to
    make an assert that a made-up filename makes just as well. The two real-world path pairs that DO
    appear (market-domains/market-urls, archive-and-remove-theme/archive-theme) are already published
    verbatim in issue #1869 and are the measurement this lib was built from; the function bodies
    around them are invented.

    Dependency-free (no Pester), same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$LibPath  = Join-Path $RepoRoot 'scripts\lib\sibling-divergence-lib.ps1'

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Label)
    if ("$Expected" -eq "$Actual") { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}
function Assert-True {
    param([bool]$Condition, [string]$Label)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label" -ForegroundColor Red }
}
function Assert-False {
    param([bool]$Condition, [string]$Label)
    if (-not $Condition) { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label" -ForegroundColor Red }
}

Write-Host ''
Write-Host '== sibling-divergence-lib.ps1 ==' -ForegroundColor Cyan

Assert-True (Test-Path -LiteralPath $LibPath) 'sibling-divergence-lib.ps1 exists at its source path'
. $LibPath

# ---------------------------------------------------------------------------------------------------
Write-Host ''
Write-Host '-- case 1: path normalization --' -ForegroundColor Cyan
# One spelling, whatever produced it. A git tree listing answers with forward slashes and a Windows
# disk walk with backslashes, so without this every shared path in a mixed-route group would read as
# two only-in paths -- the maximal false positive, and silent.

Assert-Equal 'scripts/lib/a.ps1' (ConvertTo-SiblingPath -Path 'scripts\lib\a.ps1')   'backslashes become forward slashes'
Assert-Equal 'scripts/lib/a.ps1' (ConvertTo-SiblingPath -Path './scripts/lib/a.ps1') 'a leading ./ is removed'
Assert-Equal 'scripts/lib/a.ps1' (ConvertTo-SiblingPath -Path '/scripts/lib/a.ps1')  'a leading / is removed'
Assert-Equal ''                  (ConvertTo-SiblingPath -Path '')                    'an empty path stays empty'

# ---------------------------------------------------------------------------------------------------
Write-Host ''
Write-Host '-- case 2: only the tooling layer is comparable --' -ForegroundColor Cyan
# Theme content, brains and assets are store-specific by definition. #1869 drew this boundary by hand
# before it could measure anything; the lib draws it so nobody has to draw it again.

Assert-True  (Test-IsSiblingComparablePath -Path 'scripts/task/prune-merged.ps1') 'scripts/ is comparable'
Assert-True  (Test-IsSiblingComparablePath -Path '.github/workflows/ci.yml')      '.github/ is comparable'
Assert-True  (Test-IsSiblingComparablePath -Path '.claude/settings.json')         '.claude/settings.json is comparable'
Assert-True  (-not (Test-IsSiblingComparablePath -Path 'sections/product.liquid')) 'theme content is not comparable'
Assert-True  (-not (Test-IsSiblingComparablePath -Path 'README.md'))               'a root doc is not comparable'
Assert-True  (-not (Test-IsSiblingComparablePath -Path 'assets/base.css'))         'assets are not comparable'

# ---------------------------------------------------------------------------------------------------
Write-Host ''
Write-Host '-- case 3: what is repo-specific BY DESIGN is excluded --' -ForegroundColor Cyan
# THE ASSERT THAT MATTERS MOST FOR SIGNAL. Each of these would otherwise be reported as divergence,
# and for each of them AGREEMENT would be the actual defect -- a lens describing the other repo, a
# seam holding the other store's ids. On the real BWJ pair these five patterns remove 27 of the 48
# shared paths, i.e. more than half the report.

Assert-True (-not (Test-IsSiblingComparablePath -Path '.claude/specialists/lenses/05-15-extension.md')) 'a repo lens is excluded'
Assert-True (-not (Test-IsSiblingComparablePath -Path '.claude/specialists/SPECIALISTS.md'))            'SPECIALISTS.md is excluded'
Assert-True (-not (Test-IsSiblingComparablePath -Path 'scripts/repo-config.ps1'))                       'the seam is excluded'
Assert-True (-not (Test-IsSiblingComparablePath -Path '.claude/memory/a-note.md'))                      'session memory is excluded'
Assert-True (-not (Test-IsSiblingComparablePath -Path '.github/dependabot.yml'))                        'dependabot config is excluded'

# THE TEST SUITES ARE NOT EXCLUDED, and this assert exists because excluding them is the plausible
# next move: they are noisy. They are also mechanism -- #1869's single largest divergence is a test
# suite at 1791 differing lines -- and two consumers testing the same shared lib twice is exactly the
# duplication being hunted.
Assert-True (Test-IsSiblingComparablePath -Path 'scripts/tests/plugin-scripts.tests.ps1') 'test suites stay comparable'

# ---------------------------------------------------------------------------------------------------
Write-Host ''
Write-Host '-- case 4: the grouping is declared, never inferred --' -ForegroundColor Cyan

$manifests = @(
    [pscustomobject]@{ repo = 'org/store-a'; siblingGroup = 'stores' },
    [pscustomobject]@{ repo = 'org/store-b'; siblingGroup = 'stores' },
    [pscustomobject]@{ repo = 'org/life'    }
)
$groups = Group-SiblingConsumer -Manifest $manifests

Assert-Equal 1 (@($groups.Keys).Count)         'exactly one group is formed'
Assert-Equal 2 (@($groups['stores']).Count)    'the declared group has both its members'
# The un-declared manifest is in NO group. If this ever fails, the lib has started inferring -- which
# on the real register would pair life-hub with a Shopify store.
Assert-True (-not ($groups.Keys -contains ''))  'a manifest with no siblingGroup joins no group'
$allMembers = @($groups.Values | ForEach-Object { $_ } | ForEach-Object { $_.repo })
Assert-True (-not ($allMembers -contains 'org/life')) 'the undeclared consumer appears in no group at all'

# ---------------------------------------------------------------------------------------------------
Write-Host ''
Write-Host '-- case 5: a group of one is not a group --' -ForegroundColor Cyan
# A lone member has nothing to compare against, and reporting it would make every newly-declared
# consumer a finding until its sibling is declared too.

$lonely = Group-SiblingConsumer -Manifest @([pscustomobject]@{ repo = 'org/only'; siblingGroup = 'stores' })
Assert-Equal 0 (@($lonely.Keys).Count) 'a single-member group is dropped'

$empty = Group-SiblingConsumer -Manifest @()
Assert-Equal 0 (@($empty.Keys).Count) 'an empty register produces no groups'

# ---------------------------------------------------------------------------------------------------
Write-Host ''
Write-Host '-- case 6: the path-level comparison --' -ForegroundColor Cyan

$inv = @{
    'org/a' = @{ 'scripts/shared.ps1' = 'sha-same'; 'scripts/drifty.ps1' = 'sha-a'; 'scripts/only-a.ps1' = 'sha-x' }
    'org/b' = @{ 'scripts/shared.ps1' = 'sha-same'; 'scripts/drifty.ps1' = 'sha-b'; 'scripts/only-b.ps1' = 'sha-y' }
}
$r = Compare-SiblingInventory -Inventory $inv

Assert-Equal 2 (@($r.OnlyIn).Count)  'both only-in paths are found'
Assert-Equal 1 (@($r.Drifted).Count) 'the differing shared path is drifted'
Assert-Equal 1 $r.AgreedCount        'the identical shared path is not a finding'
Assert-Equal 2 $r.SharedCount        'shared = agreed + drifted'
Assert-Equal 0 (@($r.Partial).Count) 'a two-member group has no partial class'

$onlyA = @($r.OnlyIn | Where-Object { $_.Path -eq 'scripts/only-a.ps1' })
Assert-Equal 'org/a' $onlyA[0].Member 'an only-in finding names the member that HAS the file'

# ---------------------------------------------------------------------------------------------------
Write-Host ''
Write-Host '-- case 7: a three-member group reports PARTIAL rather than losing the finding --' -ForegroundColor Cyan
# Without this class a path held by two of three members is neither only-in nor shared-by-all, and a
# binary vocabulary would drop it silently -- the failure mode that is invisible precisely because
# nothing is printed.

$inv3 = @{
    'org/a' = @{ 'scripts/two-of-three.ps1' = 'sha-1' }
    'org/b' = @{ 'scripts/two-of-three.ps1' = 'sha-1' }
    'org/c' = @{ 'scripts/elsewhere.ps1'    = 'sha-2' }
}
$r3 = Compare-SiblingInventory -Inventory $inv3
Assert-Equal 1 (@($r3.Partial).Count) 'a path held by 2 of 3 members is PARTIAL'
Assert-Equal 1 (@($r3.OnlyIn).Count)  'a path held by 1 of 3 members is still ONLY-IN'

# ---------------------------------------------------------------------------------------------------
Write-Host ''
Write-Host '-- case 8: reading function names out of PowerShell text --' -ForegroundColor Cyan

$src = @'
# a comment mentioning function Not-Real
function Get-Thing {
    param($X)
}
   function  Set-Thing  {
}
$x = "function In-A-String"
'@
$names = Get-PowerShellFunctionName -Content $src
Assert-True ($names -contains 'get-thing') 'a plain definition is found'
Assert-True ($names -contains 'set-thing') 'leading whitespace and extra spaces are tolerated'
Assert-True (-not ($names -contains 'not-real'))     'a name inside a comment is not a definition'
Assert-True (-not ($names -contains 'in-a-string'))  'a name inside a string is not a definition'
Assert-Equal 0 (@(Get-PowerShellFunctionName -Content '').Count) 'empty content yields no names'

# ---------------------------------------------------------------------------------------------------
Write-Host ''
Write-Host '-- case 9: one capability under two names -- the finding no path comparison can make --' -ForegroundColor Cyan
# The real pair from #1869. Neither file shares a path, a filename or a line with the other, and both
# export the same two functions. A path comparison reports two unrelated absences; this reports one
# duplicated mechanism.

$onlyInContent = @{
    'org/a' = @{
        'scripts/lib/market-domains.ps1' = "function Get-MarketPreviewUrls {`n}`nfunction Write-MarketPreviewUrls {`n}`n"
        'scripts/lib/solo.ps1'           = "function Get-SomethingNobodyElseHas {`n}`n"
    }
    'org/b' = @{
        'scripts/lib/market-urls.ps1'    = "function Get-MarketPreviewUrls {`n}`nfunction Write-MarketPreviewUrls {`n}`n"
    }
}
$aliased = Find-AliasedCapability -OnlyInContent $onlyInContent
Assert-Equal 2 (@($aliased).Count) 'both shared function names are reported'
Assert-True  (@($aliased | ForEach-Object { $_.Function }) -contains 'get-marketpreviewurls') 'the aliased capability is named'
# A function only one member defines is NOT aliasing. Without this, every only-in file would pair with
# itself and the class would be meaningless.
Assert-True (-not (@($aliased | ForEach-Object { $_.Function }) -contains 'get-somethingnobodyelsehas')) 'a capability only one member has is not aliased'

# SAME NAME, SAME PATH is not aliasing either -- that is an ordinary shared path, and it cannot even
# reach here, since the alias pass is fed the only-in set. Asserted anyway because the function is
# public and a later caller may feed it something wider.
$samePath = Find-AliasedCapability -OnlyInContent @{
    'org/a' = @{ 'scripts/lib/same.ps1' = "function Get-Same {`n}`n" }
    'org/b' = @{ 'scripts/lib/same.ps1' = "function Get-Same {`n}`n" }
}
Assert-Equal 0 (@($samePath).Count) 'the same name at the same path is not aliasing'

# ---------------------------------------------------------------------------------------------------
Write-Host ''
Write-Host '-- case 10: aliasing is folded onto the PATH PAIR a reader acts on --' -ForegroundColor Cyan
# Six shared names between two files is one decision, not six findings. The evidence travels along
# because a pair backed by two names is a stronger claim than one backed by a single generic helper,
# and the reader has to be able to rank them without opening anything.

$pairs = Group-AliasedCapability -Aliased $aliased
Assert-Equal 1 (@($pairs).Count) 'two shared names between one file pair fold into one finding'
Assert-Equal 2 (@($pairs[0].Functions).Count) 'the pair carries both function names as evidence'
Assert-True ($pairs[0].Pair -like '*market-domains.ps1*') 'the finding names the first path'
Assert-True ($pairs[0].Pair -like '*market-urls.ps1*')    'the finding names the second path'

# STRONGEST EVIDENCE FIRST, so the generic-helper collisions the lib's docstring predicts sort below
# the real capability pairs rather than above them.
$mixed = Find-AliasedCapability -OnlyInContent @{
    'org/a' = @{
        'scripts/lib/market-domains.ps1' = "function Get-MarketPreviewUrls {`n}`nfunction Write-MarketPreviewUrls {`n}`n"
        'scripts/tests/one.tests.ps1'    = "function New-FixtureRepo {`n}`n"
    }
    'org/b' = @{
        'scripts/lib/market-urls.ps1'    = "function Get-MarketPreviewUrls {`n}`nfunction Write-MarketPreviewUrls {`n}`n"
        'scripts/tests/two.tests.ps1'    = "function New-FixtureRepo {`n}`n"
    }
}
$mixedPairs = Group-AliasedCapability -Aliased $mixed
Assert-Equal 2 (@($mixedPairs).Count) 'two distinct file pairs are reported'
Assert-True ($mixedPairs[0].Pair -like '*market-*') 'the pair with more shared names is reported first'

Assert-Equal 0 (@(Group-AliasedCapability -Aliased @()).Count) 'no aliasing yields no pairs'

# ---------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------
Write-Host ''
Write-Host '-- case 11: the shipped index is bounded to .ps1, and that bound is the load-bearing part --' -ForegroundColor Cyan
# Every plugin ships a README.md and a SKILL.md. A basename index over all files would answer "already
# shipped" for every README in every consumer -- a false positive on the commonest filename there is,
# on the lane whose whole value is that a reader believes it.

$index = Get-ShippedScriptIndex -Shipped @(
    [pscustomobject]@{ Plugin = 'dkj-subagents-shopify'; Path = 'plugins/dkj-subagents/dkj-subagents-shopify/scripts/task/push-preview.ps1' }
    [pscustomobject]@{ Plugin = 'dkj-subagents-shopify'; Path = 'plugins\dkj-subagents\dkj-subagents-shopify\scripts\lib\sync-rules.ps1' }
    [pscustomobject]@{ Plugin = 'dkj-policy';            Path = 'plugins/dkj-policy/README.md' }
    [pscustomobject]@{ Plugin = 'dkj-policy';            Path = 'plugins/dkj-policy/skills/new-branch/SKILL.md' }
)

Assert-True  ($index.ContainsKey('push-preview.ps1')) 'a shipped .ps1 is indexed under its lower-cased basename'
Assert-True  ($index.ContainsKey('sync-rules.ps1'))   'a backslash-spelled shipped path is indexed too'
Assert-False ($index.ContainsKey('readme.md'))        'a shipped README.md is NOT indexed -- it would match every consumer'
Assert-False ($index.ContainsKey('skill.md'))         'a shipped SKILL.md is NOT indexed either'
Assert-Equal 2 (@($index.Keys).Count)                 'only the two .ps1 names are in the index'

# ONE NAME, TWO SITES. A registered mirror and the plugin file it mirrors to are the same script by
# construction, and naming only one of them sends the reader looking for the other.
$twoSites = Get-ShippedScriptIndex -Shipped @(
    [pscustomobject]@{ Plugin = 'dkj-policy'; Path = 'plugins/dkj-policy/scripts/task/new-branch.ps1' }
    [pscustomobject]@{ Plugin = 'dkj-policy'; Path = 'scripts/task/new-branch.ps1' }
)
Assert-Equal 2 (@($twoSites['new-branch.ps1']).Count) 'one name can be shipped from two sites'

# The same site twice -- a path registered AND walked -- is one site, not two.
$dupe = Get-ShippedScriptIndex -Shipped @(
    [pscustomobject]@{ Plugin = 'dkj-policy'; Path = 'plugins/dkj-policy/scripts/task/new-branch.ps1' }
    [pscustomobject]@{ Plugin = 'dkj-policy'; Path = 'plugins\dkj-policy\scripts\task\new-branch.ps1' }
)
Assert-Equal 1 (@($dupe['new-branch.ps1']).Count) 'the same site under two slash spellings is deduplicated'

Assert-Equal 0 (@((Get-ShippedScriptIndex -Shipped @()).Keys).Count) 'an empty shipped set yields an empty index'

# ---------------------------------------------------------------------------------------------------
Write-Host ''
Write-Host '-- case 12: the adoption gap neither ONLY-IN nor DRIFTED can state --' -ForegroundColor Cyan
# #1885's measurement, in its two real shapes. dkj-subagents-shopify ships push-preview.ps1 and
# sync-rules.ps1; both stores carry their own push-preview (DRIFTED) and only one still carries a
# sync-rules (ONLY-IN). Neither verdict contains the fact that decides what to do -- that the
# mechanism already has an owner.

$shopIndex = Get-ShippedScriptIndex -Shipped @(
    [pscustomobject]@{ Plugin = 'dkj-subagents-shopify'; Path = 'plugins/dkj-subagents/dkj-subagents-shopify/scripts/task/push-preview.ps1' }
    [pscustomobject]@{ Plugin = 'dkj-subagents-shopify'; Path = 'plugins/dkj-subagents/dkj-subagents-shopify/scripts/lib/sync-rules.ps1' }
)
$comparison = Compare-SiblingInventory -Inventory @{
    'org/a' = @{
        'scripts/task/push-preview.ps1' = 'aaa'
        'scripts/lib/only-ours.ps1'     = 'ccc'
    }
    'org/b' = @{
        'scripts/task/push-preview.ps1' = 'bbb'
        'scripts/lib/sync-rules.ps1'    = 'ddd'
    }
}
$gaps = Find-ShippedMechanism -Comparison $comparison -Index $shopIndex

Assert-Equal 2 (@($gaps).Count) 'both the drifted copy and the only-in copy are reported as adoption gaps'
Assert-Equal 'scripts/lib/sync-rules.ps1'    $gaps[0].Path  'the only-in path is reported'
Assert-Equal 'only-in'                       $gaps[0].Class 'and it carries the class it came from'
Assert-Equal 'org/b'                         (@($gaps[0].Members) -join ',') 'naming the single member that carries it'
Assert-Equal 'scripts/task/push-preview.ps1' $gaps[1].Path  'the drifted path is reported'
Assert-Equal 'drifted'                       $gaps[1].Class 'and it carries the class it came from'
Assert-Equal 2 (@($gaps[1].Members).Count)   'naming both members that carry a copy'
Assert-Equal 'dkj-subagents-shopify' $gaps[1].Shipped[0].Plugin 'the finding names the plugin that already owns it'
Assert-True  ($gaps[1].Shipped[0].Path -like '*dkj-subagents-shopify*push-preview.ps1') 'and the path it ships at'

# THE FINDING THIS LANE MUST NOT MAKE: a path nothing ships. scripts/lib/only-ours.ps1 is only-in and
# stays only-in -- an index miss is silence, not a weaker claim.
Assert-Equal 0 (@($gaps | Where-Object { $_.Path -eq 'scripts/lib/only-ours.ps1' }).Count) 'a path no plugin ships is not reported'

# ADDS, NEVER RECLASSIFIES. The comparison the three older lanes print from is untouched, so a
# coincidental filename match can cost a reader a file to open and can never delete a real finding.
Assert-Equal 1 (@($comparison.Drifted).Count) 'the drifted finding still stands after the shipped lane ran'
Assert-Equal 2 (@($comparison.OnlyIn).Count)  'both only-in findings still stand'

# A PARTIAL IS A LOCAL COPY TOO. #1885 names only only-in and drifted, but excluding partial would put
# a hole in the lane that opens the first time a group gains a third member.
$threeWay = Compare-SiblingInventory -Inventory @{
    'org/a' = @{ 'scripts/lib/sync-rules.ps1' = 'aaa' }
    'org/b' = @{ 'scripts/lib/sync-rules.ps1' = 'bbb' }
    'org/c' = @{ 'scripts/lib/other.ps1'      = 'ccc' }
}
$partialGaps = Find-ShippedMechanism -Comparison $threeWay -Index $shopIndex
Assert-Equal 1         (@($partialGaps).Count) 'a path held by two of three members is reported'
Assert-Equal 'partial' $partialGaps[0].Class   'and is labelled partial rather than folded into drifted'

Assert-Equal 0 (@(Find-ShippedMechanism -Comparison $comparison -Index @{}).Count) 'an empty index reports nothing'

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "FAILED: $($script:pass) passed, $($script:fail) failed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: $($script:pass) passed." -ForegroundColor Green
exit 0

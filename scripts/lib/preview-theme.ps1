<#
.SYNOPSIS
    The 'shopify theme push' argument lists push-preview.ps1 hands to the CLI, the flag whitelist in
    front of them, and the two pure readers of the CLI's own output.

.DESCRIPTION
    WHY THIS LIB EXISTS AT ALL. A consumer's push-preview built its create call inline as
    '--unpublished --theme-name <name>'. There is no --theme-name flag in the Shopify CLI -- the name of
    a new unpublished theme is passed with --theme, the same flag an existing theme's id uses. The call
    failed with 'Nonexistent flag: --theme-name' the FIRST time anybody needed a preview theme created,
    on 2026-08-21: the lazy-create path had been written the day before and no branch had wanted a preview
    theme in between. Nothing was wrong with the reasoning; the code had simply never run. A script whose
    only untested path is the one that runs once per branch breaks in front of the person who needed it
    most. Inbound #805.

    SO THE ARGUMENT LIST IS BUILT HERE, BY A FUNCTION, and checked against a flag whitelist measured off
    'shopify theme push --help'. A misspelled or invented flag now fails with a message that names the
    flag and says where the list came from, instead of a CLI error halfway through a run. The whitelist
    earned its place on its first run in the consumer: it refused the lib's own call because --unpublished
    had been left out of the list. Same class of error, caught in three seconds instead of a day.

    WHAT THE WHITELIST ANSWERS, AND WHAT IT DELIBERATELY DOES NOT. It answers "is this a real CLI flag",
    never "may this repo use it" -- so it ADMITS --allow-live. Refusing a live push is the live-theme
    guard's job (team-shopify's PreToolUse hook), and a validator answering both questions would give two
    different answers to the same one.

    WHAT THIS DELIBERATELY DOES NOT DO. It runs nothing. It builds and validates argument lists and reads
    the CLI's output; push-preview.ps1 invokes them. That split is the whole reason it is testable without
    a store, a network or a theme -- see scripts/tests/push-preview.tests.ps1.

    WHAT STAYS IN THE CONSUMER. Which theme is live (Get-ShopifyLiveThemeId), the store domain
    (Get-ShopifyStoreDomain), the branch-to-theme-name mapping, and the market/locale table a
    multi-market store prints preview URLs from (the optional Get-ShopifyPreviewUrls seam). The last of
    those is genuinely per-store rather than merely unshared: one consumer runs one domain with
    locale-prefixed paths, another runs five separate domains, so a shared table would have produced four
    domains that do not exist.

    No Set-StrictMode here: dot-sourcing would modify the calling script's strict mode.
    Pure ASCII (repo convention for .ps1).
#>

# Measured from 'shopify theme push --help' on 2026-08-21, CLI 3.94.3. Long forms only: the scripts never
# write short forms, and accepting '-t' here would let a typo like '-tt' through on a technicality.
# WHEN THE CLI CHANGES, RE-MEASURE RATHER THAN EDIT FROM MEMORY -- that command prints the whole set:
#   shopify theme push --help
# A test cannot tell a stale whitelist from a correct one, which is why the instruction lives here.
$script:ThemePushFlags = @(
    '--allow-live',
    '--development',
    '--development-context',
    '--environment',
    '--ignore',
    '--json',
    '--listing',
    '--live',
    '--no-color',
    '--nodelete',
    '--only',
    '--password',
    '--path',
    '--publish',
    '--store',
    '--strict',
    '--theme',
    '--unpublished',
    '--verbose'
)

# The three query parameters the Shopify admin itself hangs on a preview link. Without them the preview
# holds only through the cookie and is lost at the first internal link -- and then you are silently
# looking at live while believing you are looking at the preview. A consumer lost a whole review to that
# on 2026-08-05, which is why these travel with the plugin rather than being each repo's discovery.
$script:ThemePreviewQuery = '_ab=0&_fd=0&_sc=1'

function Get-ThemePushFlags {
    <# The whitelist itself, so a test can hold it against the CLI rather than against a copy. #>
    $script:ThemePushFlags
}

function Test-ThemePushArgs {
    <# Throws when an argument that LOOKS like a flag is not one 'shopify theme push' accepts. Returns
       $true otherwise, so a caller can write '$null = Test-ThemePushArgs -Arguments $a' and have the run
       stop before the CLI is invoked. Only '--*' tokens are judged: a VALUE that happens to start with a
       dash is a value. #>
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Arguments)

    $unknown = @($Arguments | Where-Object { $_ -like '--*' } |
        Where-Object { $script:ThemePushFlags -notcontains $_ })

    if ($unknown.Count -gt 0) {
        throw ("Not a 'shopify theme push' flag: " + ($unknown -join ', ') +
            ". The accepted set was measured from 'shopify theme push --help' (CLI 3.94.3) and lives in " +
            "the preview-theme lib; re-measure with that command rather than guessing.")
    }
    $true
}

function Get-ThemeCreateArgs {
    <# The call that CREATES a new unpublished theme and pushes the working tree to it in one go.
       --unpublished creates it; --theme carries the NAME (not an id) for a theme that has none yet.
       That double duty of --theme is exactly what the retired --theme-name spelling got wrong. #>
    param(
        [Parameter(Mandatory = $true)][string]$Store,
        [Parameter(Mandatory = $true)][string]$ThemeName
    )

    # Shopify rejects a theme name containing '/', which is the whole reason a branch name has to be
    # flattened before it can be one. A caller that passes the raw branch name would otherwise get an
    # opaque CLI error, so the remedy is named here instead.
    if ($ThemeName.Contains('/')) {
        throw ("A Shopify theme name may not contain '/': '$ThemeName'. Pass the flattened form -- the " +
            "branch with its slashes replaced by dashes (Get-BranchInfo's SafeName, where the repo has it).")
    }
    if ([string]::IsNullOrWhiteSpace($ThemeName)) { throw "Get-ThemeCreateArgs: -ThemeName must not be blank." }

    $a = @('theme', 'push', '--store', $Store, '--unpublished', '--theme', $ThemeName, '--json')
    $null = Test-ThemePushArgs -Arguments $a
    $a
}

function Get-ThemeUpdateArgs {
    <# The call that pushes to a theme that ALREADY exists, by id. No --json: the caller reads the exit
       code and prints the preview URLs itself, and --json here would only hide the CLI's progress. #>
    param(
        [Parameter(Mandatory = $true)][string]$Store,
        [Parameter(Mandatory = $true)][string]$ThemeId
    )

    # A NAME PASSED WHERE AN ID BELONGS is the mistake that would silently create a SECOND theme, so this
    # insists on digits rather than trusting the caller.
    if ($ThemeId -notmatch '^\d+$') {
        throw ("Get-ThemeUpdateArgs: -ThemeId must be all digits, got '$ThemeId'. A NAME goes through " +
            "Get-ThemeCreateArgs; this function is for an id that already exists.")
    }

    $a = @('theme', 'push', '--store', $Store, '--theme', $ThemeId)
    $null = Test-ThemePushArgs -Arguments $a
    $a
}

function Get-ThemeIdFromPushOutput {
    <# The id of the theme 'theme push --unpublished --json' just created, or '' where the output carries
       none. Pure string in, string out.

       ITS OWN FUNCTION BECAUSE IT IS THE HALF THAT CANNOT BE RE-RUN. The create call pushes at the same
       time it creates, so a missed id means the next run cannot find the theme by id and falls back to a
       name lookup -- recoverable, but only because the fallback exists. Parsing it inline left the one
       expression nobody could test without a store. #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Output)
    $m = ([regex]'"id"\s*:\s*(\d+)').Match($Output)
    if ($m.Success) { return $m.Groups[1].Value }
    return ''
}

function Get-ThemeByName {
    <# The theme with this exact name out of 'shopify theme list --json' output, already parsed from JSON.
       Returns $null where none matches, and THROWS where more than one does -- two themes of one name is
       an estate problem the caller has to resolve with an explicit id, not a coin flip.

       THE WRAPPER TEST IS ON THE PROPERTY, NOT ON TRUTHINESS, and that is a measured trap rather than
       style. '$array.themes' does member enumeration in PowerShell 5.1 and yields an array with a $null
       per element; that array is not empty and is therefore truthy, so a bare 'if ($parsed.themes)'
       throws away the right list. A consumer hit exactly this on 2026-08-04 and its name lookup then
       always reported 'no preview theme found'. #>
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Parsed,
        [Parameter(Mandatory = $true)][string]$ThemeName
    )
    if ($null -eq $Parsed) { return $null }
    $themes = $Parsed
    if ($themes -isnot [System.Array] -and $themes.PSObject.Properties.Name -contains 'themes') {
        $themes = $themes.themes
    }
    $hit = @(@($themes) | Where-Object { $_ -and $_.name -eq $ThemeName })
    if ($hit.Count -gt 1) {
        throw "More than one theme is called '$ThemeName' -- pass an explicit -ThemeId rather than letting this guess."
    }
    if ($hit.Count -eq 0) { return $null }
    return $hit[0]
}

function Get-ThemePreviewUrl {
    <# The one preview URL every store has: the store's own domain with preview_theme_id, carrying the
       three parameters the admin itself adds.

       THIS IS THE GENERAL HALF OF A JOB WHOSE OTHER HALF IS NOT. A multi-market store wants one URL per
       market or locale, and that table is genuinely per-store -- so it stays behind the optional
       Get-ShopifyPreviewUrls seam. What is NOT per-store is that a preview link needs those three
       parameters to survive the first internal click, and a repo without the seam should still get a link
       that works rather than none at all. #>
    param(
        [Parameter(Mandatory = $true)][string]$Store,
        [Parameter(Mandatory = $true)][string]$ThemeId,
        [string]$Path = '/'
    )
    if (-not $Path) { $Path = '/' }
    if (-not $Path.StartsWith('/')) { $Path = '/' + $Path }
    # A SEAM ANSWER IS TAKEN AS GIVEN AND NORMALISED ANYWAY: a repo may state its store as a bare domain,
    # with a scheme, or with a trailing slash, and none of those is wrong -- but concatenating them
    # unexamined yields 'https://https://x//'.
    $domain = ($Store -replace '^https?://', '') -replace '/+$', ''
    # Built by concatenation rather than interpolation: '$Path?' reads badly next to PowerShell's own '$?'
    # and the query is assembled from three parts anyway.
    return 'https://' + $domain + $Path + '?preview_theme_id=' + $ThemeId + '&' + $script:ThemePreviewQuery
}

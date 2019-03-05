#!/usr/bin/env nix-shell
#!nix-shell -i bash ./default.nix -I nixpkgs=channel:nixos-unstable-small

{
    cd nixpkgs
    rev=$(git rev-parse HEAD)
    export LOGFILE="./reproducibility-log-$rev"
    cd ..

    cp "$LOGFILE" "./public/"

    reproducible=$(cat "$LOGFILE" | grep '^reproducible' | wc -l)
    total=$(cat "$LOGFILE" | wc -l)
    percent=$(printf "%.3f" "$(echo "($reproducible / $total) * 100" | bc -l)")

    cat <<EOF
<html>
<head>
<title>Is NixOS Reproducible?</title>
<meta name="description" content="nixos-unstable's iso_minimal.x86_64-linux build is $percent% reproducible!" />

<!-- Twitter Card data -->
<meta name="twitter:card" value="summary">

<!-- Open Graph data -->
<meta property="og:title" content="Is NixOS Reproducible?" />
<meta property="og:type" content="article" />
<meta property="og:url" content="https://r13y.com/" />
<meta property="og:image" content="https://nixos.org/logo/nixos-logo-only-hires.png" />
<meta property="og:description" content="nixos-unstable's iso_minimal.x86_64-linux build is $percent% reproducible!" />
<style>
body {
    max-width: 50em;
    margin-left: auto;
    margin-right: auto;
}

.logo {
  display: flex;
}

.logo__letter {
  font-size: 200%;
  align-self: flex-end;
}

.logo__middle {
  display: flex;
  flex-direction: column;
  padding-left: 3px;
  margin-right: -5px;
}

.logo__count {
  text-align: center;
  padding-top: 6px;
}

.logo__text {
  font-variant: small-caps;
  border-top: 1px solid black;
  font-size: 50%;
}
</style>
</head>
<body>
<h1 class="logo">
  <span class="logo__letter logo__letter--start">R</span>
  <span class="logo__middle">
    <span class="logo__count">13</span>
    <span class="logo__text">eproducibilit</span>
  </span>
  <span class="logo__letter logo__letter--end">Y: NixOS</span>
</h1>
<h1>Is NixOS Reproducible?</h1>
<h2>Tracking: <code>nixos-unstable</code>'s
    <code>iso_minimal</code> job for <code>x86_64-linux</code>.</h2>
<p>Build via:</p>
<pre>
git clone https://github.com/nixos/nixpkgs.git
cd nixpkgs
git checkout $rev
nix-build ./nixos/release-combined.nix -A nixos.iso_minimal.x86_64-linux
</pre>

<h1 style="color: green">$reproducible / $total ($percent%) are reproducible!</h1>
<hr>
<h3>unreproduced paths</h3>
<ul>
EOF

    for drv in $(cat "$LOGFILE" | awk '$1 == "unreproducible" { print $2; }'); do
        cat <<EOF
<li><a href="./diff/$(basename "$drv").html">(diffoscope)</a> <a href=".$drv">(drv)</a> <code>$drv</code></li>
EOF
    done

    cat <<EOF
</ul>
<p><a href="./$LOGFILE">full list of build results</a></p>
<hr />
<h3 id="test-circumstance">How are these tested?</h3>
<p>Each build is run twice, at different times, on different hardware

running different kernels.</p>

<h3 id="result-confidence">How confident can we be in the results?</h3>

<p>Fairly. We don't currently inject randomness at the filesystem
layer, but many of the reproducibility issues are being exercised
already. It isn't possible to <em>guarantee</em> a package is
reproducible, just like it isn't possible to prove software is
bug-free. It is possible there is nondeterminism in a package source,
waiting for some specific circumstance.</p>

<p>This is why we run these tests: to track how we are doing over
time, to submit bug fixes for nondeterminism when we find them.</p>

<h3 id="next-steps">How can we do better?</h3>

<p>There are further steps we could take. For example, the next likely
step is using
<a href="https://salsa.debian.org/reproducible-builds/disorderfs">disorderfs</a>
which injects additional nondeterminism by reordering directory entries.
</p>

<h3 id="how-do-i-check">How can I test my patches?</h3>
<p>Nix has built-in support for checking a path is reproducible. There
are two routes.</p>

<p>Pretending you are debugging a nondeterminism bug in
<code>hello</code>. To check it, you build the package, and then
build it again with <code>--check --keep-failed</code>. This will
provide the differing output in a separate directory which you can
use <code>diffoscope</code> on.</p>

<pre>
$ nix-build . -A hello
$ nix-build . -A hello --check --keep-failed
[...snip...]
error: derivation '/nix/store/...hello.drv' may not be deterministic:
output '/nix/store/...-hello' differs from '/nix/store/...hello.check'
$ diffoscope /nix/store/...hello /nix/store/...hello.check
</pre>

<p>Note: the <code>.check</code> output is not a valid store path, and
will automatically be deleted on the next run of the Nix garbage
collector.</p>

<p><small>There is support for an automatic <code>diff-hook</code> in
Nix 2, but it is much more complicated to set up. If you would like to
work on this, or need help setting it up, contact gchristensen on
Freenode. We can work together to write docs on how to use it.</small>
</p>

<hr />

<small>Generated at $(TZ=UTC date) from
<a href="https://github.com/grahamc/r13y.com">https://github.com/grahamc/r13y.com</a></small>
<center><img style="max-width: 100px" src="https://nixos.org/logo/nixos-logo-only-hires.png" /></center>
</body></html>
EOF
}

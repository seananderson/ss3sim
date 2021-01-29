ss3sim
======

master: [![R-CMD-check](https://github.com/ss3sim/ss3sim/workflows/R-CMD-check/badge.svg)](https://github.com/ss3sim/ss3sim/actions?query=workflow%3AR-CMD-check) [![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/ss3sim)](https://cran.r-project.org/package=ss3sim)

development: [![R-CMD-check](https://github.com/ss3sim/ss3sim/workflows/R-CMD-check/badge.svg?branch=development)](https://github.com/ss3sim/ss3sim/actions?query=workflow%3AR-CMD-check)

ss3sim is an R package that facilitates flexible, rapid, and reproducible fisheries stock assessment simulation testing with the widely-used [Stock Synthesis](https://vlab.ncep.noaa.gov/web/stock-synthesis) (SS) statistical age-structured stock assessment framework. To learn more, read on or check out the [vignettes](http://ss3sim.github.io/ss3sim/).

Contents
--------

-   [Installing the ss3sim R package](#installing-the-ss3sim-r-package)
-   [The ss3sim simulation setup](#the-ss3sim-simulation-setup)
-   [How ss3sim works](#how-ss3sim-works)
-   [Example output from an ss3sim simulation](#example-output-from-an-ss3sim-simulation)
-   [Papers published using ss3sim](#papers-published-using-ss3sim)
-   [Citing ss3sim](#citing-ss3sim)
-   [Contributing to ss3sim](#contributing-to-ss3sim)
-   [Code of conduct](#code-of-conduct)

<!-- end toc -->
Installing the ss3sim R package
-------------------------------

Install the [CRAN version](https://cran.r-project.org/package=ss3sim) of ss3sim with:

``` r
install.packages("ss3sim")
```

Or, install the development version from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("ss3sim/ss3sim", 
  ref = "development", build_vignettes = TRUE, dependencies = TRUE)
library(ss3sim)
```

We suggest using the GitHub version because it comes with the SS executable/binary. If you are using the CRAN version, you'll need to install the binary and place it in your system path. See the Introduction vignette with `vignette("introduction", "ss3sim")` for more details on how to get the latest version of SS and place it in your path.

You can read the help files and access the vignettes for reproducible examples of ss3sim simulations with

``` r
?ss3sim
browseVignettes("ss3sim")
```

The ss3sim simulation setup
---------------------------

An ss3sim simulation requires three types of input:

1.  a base model of the underlying truth (an SS operating model)
2.  a base model of how you will assess that truth (an SS estimation model),
3.  a set of cases that deviate from these base models that you want to compare (configuration arguments provided as plain-text control files).

You can find examples of these SS operating and estimation models [within the package data](https://github.com/ss3sim/ss3sim/tree/master/inst/extdata/models). Plain-text case files for some current simulation projects run by the developers of the package are [also available](https://github.com/ss3sim/ss3sim/tree/master/inst/extdata/eg-cases) along with the [case files for the examples](https://github.com/ss3sim/ss3sim/tree/master/inst/extdata/eg-cases) used in the paper and vignette.

![An illustration of the input and output file and folder structure.](https://raw.githubusercontent.com/ss3sim/ss3sim/f763cfb462a9e68db670155070cd554812a65160/man/figures/filestructure.png)

An illustration of the input and output file and folder structure.

How ss3sim works
----------------

ss3sim works by converting simulation arguments (e.g., a given natural mortality trajectory) into manipulations of SS configuration files. It takes care of running the operating and estimation models as well as making these manipulations at the appropriate stage in the simulation.

ss3sim functions are divided into three types:

1.  `change` and `sample` functions that manipulate SS configuration files. These manipulations generate an underlying "truth" (operating models) and control our assessment of those models (estimation models).

2.  `run` functions that conduct simulations. These functions generate a folder structure, call manipulation functions, run SS3 as needed, and save the output.

3.  `get` functions for synthesizing the output.

Example output from an ss3sim simulation
----------------------------------------

![An example of ss3sim output](https://raw.github.com/seananderson/ss3sim/master/inst/ms/fig2-20131109.png)

Example output from an ss3sim simulation. This example shows a crossed simulation in which we considered (1) the effect of fixing natural mortality (*M*) at its true value (0.2; case E0) or estimating *M* (case E1) and (2) the effect of high survey effort (sigma\_survey = 0.1; case D0) or low survey effort (sigma\_survey = 0.4; case D1). Upper panels (blue) show time series of relative error in spawning stock biomass (SSB). Lower panels (gray) show the distribution of relative error across four scalar variables: depletion, *M*, SSB at maximum sustainable yield (SSB\_MSY), and fishing mortality (*F*) in the terminal year. We show the values across simulation iterations with dots and the distributions with beanplots (kernel density smoothers).

Citing ss3sim
-------------

If you use ss3sim in a publication, please cite ss3sim as shown by

``` r
citation("ss3sim")
toBibtex(citation("ss3sim"))
```

Contributing to ss3sim
----------------------

Interested in contributing to ss3sim? We recognize contributions come in many forms, including but not limited to code, reporting issues, creating examples and/or documentation. Please see the [CONTRIBUTING guide](CONTRIBUTING).

Code of conduct
---------------

This project and everyone participating in it is governed by the [NMFS Fisheries Toolbox Code of Conduct](https://github.com/nmfs-fish-tools/Resources/blob/master/CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [fisheries.toolbox@noaa.gov](mailto:fisheries.toolbox@noaa.gov). Note that the maintainers of ss3sim do not have access to this email account, so unacceptable behavior of maintainers can also be reported here.


Disclaimer
----------

"The United States Department of Commerce (DOC) GitHub project code is provided on an 'as is' basis and the user assumes responsibility for its use. DOC has relinquished control of the information and no longer has responsibility to protect the integrity, confidentiality, or availability of the information. Any claims against the Department of Commerce stemming from the use of its GitHub project will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by DOC or the United States Government."

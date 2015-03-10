# emacs: -*- mode: python; py-indent-offset: 4; tab-width: 4; indent-tabs-mode: nil -*-
# ex: set sts=4 ts=4 sw=4 noet:
# ## ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ##
#
#   See COPYING file distributed along with the datalad package for the
#   copyright and license terms.
#
# ## ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ##

import git
import os

from .utils import eq_, ok_, with_testrepos, with_tempfile
from commands import getstatusoutput

@with_testrepos(flavors=['local'])
def test_having_annex(path):
    ok_(os.path.exists(os.path.join(path, '.git')))
    repo = git.Repo(path)
    # might not necessarily be present upon initial submodule init
    #branches = [r.name for r in repo.branches]
    #ok_('git-annex' in branches, msg="Didn't find git-annex among %s" % branches)
    # look for it among remote refs
    refs = [_.name for _ in repo.remote().refs]
    ok_('origin/git-annex' in refs, msg="Didn't find git-annex among refs %s"
                                        % refs)

@with_testrepos(flavors=['network'])
def test_point_to_github(url):
    ok_('github.com' in url)
    ok_(url.startswith('git://github.com/datalad/testrepo--'))

@with_testrepos
@with_tempfile
def test_clone(src, tempdir):
    """Verify that all our repos are clonable"""
    status, output = getstatusoutput("git clone %(src)s %(tempdir)s" % locals())
    eq_(status, 0, msg="Status: %d  Output was: %r" % (status, output))
    ok_(os.path.exists(os.path.join(tempdir, ".git")))
    # TODO: requires network for sure! ;)
    # TODO: figure out why fails on travis  -- demands init first! bleh
    #  but since this is not a purpose of this test really -- screw it
    #status1, output1 = getstatusoutput("cd %(tempdir)s && git annex get --from=web test-annex.dat"
    #                                   % locals())
    #eq_(status1, 0, msg="Status: %d  Output was: %r" % (status1, output1))
    #ok_("get test-annex.dat" in output1)
TEXS = DocMain.tex Configuration.tex CrawlerOperation.tex DocMain.tex documentation.tex FAQ.tex Intro.tex \
 OpenSourceDistr.tex SystemComponents.tex ExpectedPerformance.tex  ClassificationEval.tex
GENTEXS = ConfigVars.tex DepGraph.tex ManPages.tex SQL.tex InstallationTest.tex PlugInTemplate.tex
IMGS = CrawlerArchitecture.xfig.eps TopicFilter.xfig.eps CrawlerSpeed.ps Config.ps focusedrobot.eps
BINS = ../bin/combine*
MODULES = ../Combine/*.pm

all : pdf ps html
dvi : DocMain.dvi
pdf : DocMain.pdf
ps  : DocMain.ps

DocMain.pdf : DocMain.dvi
	    dvipdf DocMain.dvi DocMain.pdf

DocMain.ps : DocMain.dvi
	   dvips -o DocMain.ps DocMain.dvi

tex : $(TEXS) $(GENTEXS) $(IMGS) myalvis.bib
	latex DocMain.tex

DocMain.dvi : $(TEXS) $(GENTEXS) $(IMGS) myalvis.bib
	    latex DocMain.tex
	    bibtex DocMain
	    latex DocMain.tex
	    latex DocMain.tex

ConfigVars.tex : ../conf/default.cfg ../conf/job_default.cfg $(BINS) $(MODULES) genConfigDoc.pl
	./genConfigDoc.pl > ConfigVars.tex

DepGraph.tex : $(BINS) $(MODULES) genDepGraph.pl
	./genDepGraph.pl > DepGraph.tex

ManPages.tex : $(BINS) $(MODULES) genPod2latex.pl
	./genPod2latex.pl > ManPages.tex

SQL.tex : ../bin/combineINIT extrSQLdoc.pl
	./extrSQLdoc.pl > SQL.tex

InstallationTest.tex : InstallationTest.pl genInstTest.pl
	./genInstTest.pl > InstallationTest.tex

PlugInTemplate.tex : ../templates/classifyPlugInTemplate.pm genPlugInTemplate.pl
	./genPlugInTemplate.pl > PlugInTemplate.tex

html : DocMain.dvi
	latex2html --split 4 --local_icons DocMain.tex
	\rm -rf HTML
	mv DocMain HTML

clean :
	\rm -rf HTML *.aux *.log *.dvi DocMain.ps DocMain.pdf *.toc $(GENTEXS)

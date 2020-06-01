---
layout: page-not-on-sidebar
title: "The Terribly Clever(ly&nbsp;Terrible) Code"
description: >
  The actual worst code I have ever written.
image: /files/sat2vec/Pasternak_The_Night_Before_the_Exam.jpg
image_alt: >
  An impressionistic painting titled "Night Before the Exam" by Leonid
  Pasternak. The painting shows four students sitting around a kitchen table
  studying for a exam. One student holds a skull, while the others longue
  around smoking or studying books or papers.
permalink: blog/cleverly-worst-code/the-code-itself/
---

How bad can my bad code be? Really bad! Find out what I was thinking, and how
I would do it better in: [_My Terribly Clever(ly&nbsp;Terrible)
Code_][blog].

[blog]: {% post_url 2020-03-30-cleverly_worst_code %}

```cpp
#include "TFile.h"
#include "TList.h"
#include "TGraph.h"
#include "TTree.h"
#include "TGraphAsymmErrors.h"
#include "TKey.h"
#include "EfficiencyStatistics.h"
#include "TH2.h"

inline bool my_isnan(double x) {
    return x != x;
}

bool wasScan(int irun) {
    static const int nruns[] = {132442, 132476, 132477, 132959, 132960, 132961, 132965, 132968, -1 };

    if (irun >= 132645 && irun <= 132661) {
        return true;
    }
    for (int i = 0; nruns[i] > 0; i++)
        if (irun == nruns[i]) {
            return true;
        }

    if (irun > 134600 && irun < 134800) {
        return true;    // actually, not true.. (900 GeV)
    }

    return false;
}

void plotPerf_alex(TFile* inFile, int ttNumber, int vertNumber,
                   bool plotPulls = false) {

    /* These arrays hold the data to be ploted */
    double xRunNumber[1000];
    double yEfficiency[1000];
    double xError[1000]; // Symetric so only need one
    double yErrorPlus[1000];
    double yErrorMinus[1000];

    struct PerfTree {
        int irun;
        int ivertv0;
        int itt8v0;
        int itt9v0;
        int itt10v0;
        int itt40v0;
        int itt41v0;
        int ivertv1;
        int itt8v1;
        int itt9v1;
        int itt10v1;
        int itt40v1;
        int itt41v1;
        int ivertv2;
        int itt8v2;
        int itt9v2;
        int itt10v2;
        int itt40v2;
        int itt41v2;
        int ivertv3;
        int itt8v3;
        int itt9v3;
        int itt10v3;
        int itt40v3;
        int itt41v3;
        int ivertv4;
        int itt8v4;
        int itt9v4;
        int itt10v4;
        int itt40v4;
        int itt41v4;
        float ave;
    };

    PerfTree currentPerf;
    /* Open up the inFile and get its branch */
    TTree* currentTree = (TTree*)inFile->Get("TrigPerf");
    TBranch* currentBranch = currentTree->GetBranch("perf");
    currentBranch->SetAddress(&currentPerf);

    int nPoints = 0; // Going to be used to count the points assigned

    /* These will be used to set Max and Min X range */
    int minRun = 1000000000;
    int maxRun = 0;

    for (int i = 0; i < currentTree->GetEntries(); i++) {

        currentTree->GetEntry(i);
        xRunNumber[nPoints] = currentPerf.irun;

        int inum = 0;
        double ivert = 0;
        double lve = 0.73;

        /* Sets certain variables depending on the trigger we're looking at */
        int primeOne, primeTwo;

        /* OK! I know... I should learn to make arrays of pointers...
         *
         * This code assigns each number of vertices
         * and each trigger a unique prime.
         * It then multiples these to create a new
         * unique number.
         *
         * We then use this number to do a switch
         */

        switch (ttNumber) {
            case 8:
                primeOne = 11;
                break;
            case 9:
                primeOne = 13;
                break;
            case 10:
                primeOne = 17;
                break;
            case 40:
                primeOne = 19;
                break;
            case 41:
                primeOne = 23;
                break;
        }
        switch (vertNumber) {
            case 0:
                primeTwo = 1;
                break;
            case 1:
                primeTwo = 2;
                break;
            case 2:
                primeTwo = 3;
                break;
            case 3:
                primeTwo = 5;
                break;
            case 4:
                primeTwo = 7;
                break;
        }

        int testNumber = (primeOne * primeTwo);
        //      cout << primeOne << endl;
        //      cout << primeTwo << endl;
        //      cout << testNumber << endl;
        switch (testNumber) {
            /* Sum of vertex */
            case 1*11:
                inum = currentPerf.itt8v0 + currentPerf.itt8v1 + currentPerf.itt8v2 +
                       currentPerf.itt8v3 + currentPerf.itt8v4;
                ivert = currentPerf.ivertv0 + currentPerf.ivertv1 + currentPerf.ivertv2 +
                        currentPerf.ivertv3 + currentPerf.ivertv4;
                lve = 0.92;
                break;
            case 1*13:
                inum = currentPerf.itt9v0 + currentPerf.itt9v1 + currentPerf.itt9v2 +
                       currentPerf.itt9v3 + currentPerf.itt9v4;
                ivert = currentPerf.ivertv0 + currentPerf.ivertv1 + currentPerf.ivertv2 +
                        currentPerf.ivertv3 + currentPerf.ivertv4;
                break;
            case 1*17:
                inum = currentPerf.itt10v0 + currentPerf.itt10v1 + currentPerf.itt10v2 +
                       currentPerf.itt10v3 + currentPerf.itt10v4;
                ivert = currentPerf.ivertv0 + currentPerf.ivertv1 + currentPerf.ivertv2 +
                        currentPerf.ivertv3 + currentPerf.ivertv4;
                break;
            case 1*19:
                inum = currentPerf.itt40v0 + currentPerf.itt40v1 + currentPerf.itt40v2 +
                       currentPerf.itt40v3 + currentPerf.itt40v4;
                ivert = currentPerf.ivertv0 + currentPerf.ivertv1 + currentPerf.ivertv2 +
                        currentPerf.ivertv3 + currentPerf.ivertv4;
                lve = 0.9;
                break;
            case 1*23:
                inum = currentPerf.itt41v0 + currentPerf.itt41v1 + currentPerf.itt41v2 +
                       currentPerf.itt41v3 + currentPerf.itt41v4;
                ivert = currentPerf.ivertv0 + currentPerf.ivertv1 + currentPerf.ivertv2 +
                        currentPerf.ivertv3 + currentPerf.ivertv4;
                break;
            /* 1 vertex */
            case 2*11:
                inum = currentPerf.itt8v1;
                ivert = currentPerf.ivertv1;
                lve = 0.92;
                break;
            case 2*13:
                inum = currentPerf.itt9v1;
                ivert = currentPerf.ivertv1;
                break;
            case 2*17:
                inum = currentPerf.itt10v1;
                ivert = currentPerf.ivertv1;
                break;
            case 2*19:
                inum = currentPerf.itt40v1;
                ivert = currentPerf.ivertv1;
                lve = 0.9;
                break;
            case 2*23:
                inum = currentPerf.itt41v1;
                ivert = currentPerf.ivertv1;
                break;
            /* 2 vertex */
            case 3*11:
                inum = currentPerf.itt8v2;
                ivert = currentPerf.ivertv2;
                lve = 0.92;
                break;
            case 3*13:
                inum = currentPerf.itt9v2;
                ivert = currentPerf.ivertv2;
                break;
            case 3*17:
                inum = currentPerf.itt10v2;
                ivert = currentPerf.ivertv2;
                break;
            case 3*19:
                inum = currentPerf.itt40v2;
                ivert = currentPerf.ivertv2;
                lve = 0.9;
                break;
            case 3*23:
                inum = currentPerf.itt41v2;
                ivert = currentPerf.ivertv2;
                break;
            /* 3 vertex */
            case 4*11:
                inum = currentPerf.itt8v3;
                ivert = currentPerf.ivertv3;
                lve = 0.92;
                break;
            case 4*13:
                inum = currentPerf.itt9v3;
                ivert = currentPerf.ivertv3;
                break;
            case 4*17:
                inum = currentPerf.itt10v3;
                ivert = currentPerf.ivertv3;
                break;
            case 4*19:
                inum = currentPerf.itt40v3;
                ivert = currentPerf.ivertv3;
                lve = 0.9;
                break;
            case 4*23:
                inum = currentPerf.itt41v3;
                ivert = currentPerf.ivertv3;
                break;
            /* 4 vertex */
            case 5*11:
                inum = currentPerf.itt8v4;
                ivert = currentPerf.ivertv4;
                lve = 0.92;
                break;
            case 5*13:
                inum = currentPerf.itt9v4;
                ivert = currentPerf.ivertv4;
                break;
            case 5*17:
                inum = currentPerf.itt10v4;
                ivert = currentPerf.ivertv4;
                break;
            case 5*19:
                inum = currentPerf.itt40v4;
                ivert = currentPerf.ivertv4;
                lve = 0.9;
                break;
            case 5*23:
                inum = currentPerf.itt41v4;
                ivert = currentPerf.ivertv4;
                break;
        }

        /* Some cuts, as well as computations of Efficencies and errors */
        if (ivert < 100) {
            continue;
        }
        if (wasScan(currentPerf.irun)) {
            continue;
        }

        if (minRun > currentPerf.irun) {
            minRun = currentPerf.irun;
        }
        if (maxRun < currentPerf.irun) {
            maxRun = currentPerf.irun;
        }

        double yEfficTMP = inum / ivert;
        if (my_isnan(yEfficTMP)) {
            continue;
        }
        yEfficiency[nPoints] = yEfficTMP;

        if (yEfficiency[nPoints] < 0.1) {
            continue;    // This may cut events where there is prescaling applied
        }

        double yValue = yEfficiency[nPoints];

        xError[nPoints] = 0.0; //No error in X
        EfficiencyStatistics es(inum, ivert);
        yErrorPlus[nPoints] = 1 * (es.sigma(1) - yValue);
        yErrorMinus[nPoints] = yValue - es.sigma(-1);

        printf("%d %f %f %f %d\n", currentPerf.irun, yErrorPlus[nPoints],
               yErrorMinus[nPoints], yEfficiency[nPoints], ivert);

        nPoints++;
    }

    if (nPoints == 0) {
        return;    // Fail if no data
    }

    /* Making the plot of the data, no pulls */
    gROOT->SetStyle("Plain");

    TCanvas* c1 = new TCanvas("c1", "c1", 800, 800);
    c1->SetLeftMargin(0.15);

    char plotName[100];
    char yAxisName[100];
    char outFileName[120];
    double xRangeMin = minRun - 0.05 * (maxRun - minRun);
    double xRangeMax = maxRun + 0.05 * (maxRun - minRun);

    if (!plotPulls) {
        /* Define plotting variables and create a plot instance */
        sprintf(plotName, "Efficiency for TT%d with %d Vertex", ttNumber, vertNumber);
        sprintf(yAxisName, "N_{TT%d} / N_{Vertex}", ttNumber);

        TH2* dummy = new TH2F(plotName, plotName, 5, xRangeMin, xRangeMax, 5, lve, 1.0);
        dummy->GetXaxis()->SetNoExponent(true);
        dummy->GetXaxis()->SetTitle("Run Number");
        dummy->GetXaxis()->SetLabelSize(0.03);
        dummy->GetYaxis()->SetTitle(yAxisName);
        dummy->GetYaxis()->SetTitleOffset(1.8);
        dummy->Draw();
        dummy->SetStats(0);

        TGraphAsymmErrors* er8 = new TGraphAsymmErrors(nPoints, xRunNumber, yEfficiency,
                                                       xError, xError, yErrorMinus, yErrorPlus);
        TFitResultPtr fitResult = er8->Fit("pol0", "S");
        er8->SetMarkerStyle(23);
        er8->Draw("P");

        char fitText[120];
        sprintf(fitText, "Fit Eff = %.3f #pm %.3f", fitResult->GetParams()[0],
                fitResult->GetErrors()[0]);
        //TText* t1=new TLatex(0.2,0.8,fitText);
        TText* t1 = new TLatex(0.2, 0.2, fitText);
        t1->SetNDC(true);
        t1->Draw();

        char chisqrText[120];
        sprintf(chisqrText, "#chi^{2} = %.1f / %d dof", fitResult->Chi2(),
                fitResult->Ndf());
        //TText* t2=new TLatex(0.2,0.75,chisqrText);
        TText* t2 = new TLatex(0.2, 0.15, chisqrText);
        t2->SetNDC(true);
        t2->Draw();

        sprintf(outFileName, "eff_tt%d_%dvert.png", ttNumber, vertNumber);
        c1->Print(outFileName);

    }
    else {

        sprintf(plotName, "Pulls for TT%d with %d Vertex", ttNumber, vertNumber);
        sprintf(yAxisName, "Pull");

        TH2* dummy = new TH2F(plotName, plotName, 5, xRangeMin, xRangeMax, 5, -5.0,
                              5.0);
        dummy->GetXaxis()->SetNoExponent(true);
        dummy->GetXaxis()->SetTitle("Run Number");
        dummy->GetXaxis()->SetLabelSize(0.03);
        dummy->GetYaxis()->SetTitle(yAxisName);
        dummy->GetYaxis()->SetTitleOffset(1.8);
        dummy->Draw();
        dummy->SetStats(0);

        TGraphAsymmErrors* er8 = new TGraphAsymmErrors(nPoints, xRunNumber, yEfficiency,
                                                       xError, xError, yErrorMinus, yErrorPlus);
        TFitResultPtr fitResult = er8->Fit("pol0", "S");

        /* Calculates the pulls of the distribution */
        double pulls[1000];
        for (int i = 0; i < nPoints; i++) {
            double pullNumerator = yEfficiency[i] - (fitResult->GetParams()[0]);
            double pullDenom;
            if (pullNumerator > 0) {
                pullDenom = yErrorMinus[i];
            }
            else {
                pullDenom = yErrorPlus[i];
            }

            pulls[i] = pullNumerator / pullDenom;
            printf("%f %f %f\n", pulls[i], pullNumerator, pullDenom);
        }

        /* xError is the 0 array */
        TGraphAsymmErrors* er9 = new TGraphAsymmErrors(nPoints, xRunNumber, pulls,
                                                       xError, xError, xError, xError);
        er9->SetMarkerStyle(23);
        er9->Draw("P");

        sprintf(outFileName, "eff_tt%d_%dvert_pulls.png", ttNumber, vertNumber);
        c1->Print(outFileName);
    }
}
```

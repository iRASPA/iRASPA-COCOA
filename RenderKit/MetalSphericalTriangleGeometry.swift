//
//  MetalSphericalTriangleGeometry.swift
//  RenderKit
//
//  Created by David Dubbeldam on 08/08/2021.
//  Copyright © 2021 David Dubbeldam. All rights reserved.
//

import Foundation

// http://paulbourke.net/geometry/circlesphere/sphericaltri.c
/*
 #include "stdlib.h"
 #include "stdio.h"
 #include "math.h"

 
   //Create a spherical triangle between three points on a sphere

 typedef struct {
    double x,y,z;
 } XYZ;
 typedef struct {
    XYZ p1,p2,p3;
 } FACET3;
 #define DTOR 0.0174532925

 XYZ MidPoint(XYZ,XYZ);
 void Normalise(XYZ *);

 int main(int argc,char **argv)
 {
   int i,j;
   int n=0,nstart;
   int iterations = 2;
   FACET3 *f = NULL;
   double theta[3] = {0.0,35.0,80.0}, phi[3] = {10.0,15.0,80.0}; // corner in polar coordinates
   XYZ p1,p2,p3;

   if (argc > 1)
     iterations = atoi(argv[1]);

   // Start with the vertices of the triangle
   f = malloc(sizeof(FACET3));
   f[0].p1.x = cos(phi[0]*DTOR) * cos(theta[0]*DTOR);
    f[0].p1.y = cos(phi[0]*DTOR) * sin(theta[0]*DTOR);
    f[0].p1.z = sin(phi[0]*DTOR);
    f[0].p2.x = cos(phi[1]*DTOR) * cos(theta[1]*DTOR);
    f[0].p2.y = cos(phi[1]*DTOR) * sin(theta[1]*DTOR);
    f[0].p2.z = sin(phi[1]*DTOR);
    f[0].p3.x = cos(phi[2]*DTOR) * cos(theta[2]*DTOR);
    f[0].p3.y = cos(phi[2]*DTOR) * sin(theta[2]*DTOR);
    f[0].p3.z = sin(phi[2]*DTOR);
   n = 1;

   for (i=1;i<iterations;i++) {
     nstart = n;

     for (j=0;j<nstart;j++) {
       f = realloc(f,(n+3)*sizeof(FACET3));
   
       // Create initially copies for the new facets
       f[n  ] = f[j];
       f[n+1] = f[j];
       f[n+2] = f[j];

       // Calculate the midpoints
       p1 = MidPoint(f[j].p1,f[j].p2);
       Normalise(&p1);
       p2 = MidPoint(f[j].p2,f[j].p3);
       Normalise(&p2);
       p3 = MidPoint(f[j].p3,f[j].p1);
       Normalise(&p3);

       // Replace the current facet
       f[j].p2 = p1;
       f[j].p3 = p3;

       // Create the changed vertices in the new facets
       f[n  ].p1 = p1;
       f[n  ].p3 = p2;
       f[n+1].p1 = p3;
       f[n+1].p2 = p2;
       f[n+2].p1 = p1;
       f[n+2].p2 = p2;
       f[n+2].p3 = p3;
       n += 3;
     }
   }

   fprintf(stderr,"%d facets generated\n",n);

   // Save as STL, for simplicity only
    printf("solid\n");
    for (i=0;i<n;i++) {
       printf("facet normal 0 0 1\n");
       printf("outer loop\n");
       printf("vertex %g %g %g\n",f[i].p1.x,f[i].p1.y,f[i].p1.z);
       printf("vertex %g %g %g\n",f[i].p2.x,f[i].p2.y,f[i].p2.z);
       printf("vertex %g %g %g\n",f[i].p3.x,f[i].p3.y,f[i].p3.z);
       printf("endloop\n");
       printf("endfacet\n");
    }
    printf("endsolid");

   exit(0);
 }

 /*
    Return the midpoint between two vectors
 */
 XYZ MidPoint(XYZ p1,XYZ p2)
 {
    XYZ p;

    p.x = (p1.x + p2.x) / 2;
    p.y = (p1.y + p2.y) / 2;
    p.z = (p1.z + p2.z) / 2;

    return(p);
 }

 /*
    Normalise a vector
 */
 void Normalise(XYZ *p)
 {
    double length;

    length = sqrt(p->x * p->x + p->y * p->y + p->z * p->z);
    if (length != 0) {
       p->x /= length;
       p->y /= length;
       p->z /= length;
    } else {
       p->x = 0;
       p->y = 0;
       p->z = 0;
    }
 }

 */

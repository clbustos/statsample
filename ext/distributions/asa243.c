#include <math.h>
#include "cdf.h"


//****************************************************************************80

double alngam2 ( double xvalue, int *ifault )

//****************************************************************************80
//
//  Purpose:
//
//    ALNGAM computes the logarithm of the gamma function.
//
//  Modified:
//
//    13 January 2008
//
//  Author:
//
//    Allan Macleod
//    C++ version by John Burkardt
//
//  Reference:
//
//    Allan Macleod,
//    Algorithm AS 245,
//    A Robust and Reliable Algorithm for the Logarithm of the Gamma Function,
//    Applied Statistics,
//    Volume 38, Number 2, 1989, pages 397-402.
//
//  Parameters:
//
//    Input, double XVALUE, the argument of the Gamma function.
//
//    Output, int IFAULT, error flag.
//    0, no error occurred.
//    1, XVALUE is less than or equal to 0.
//    2, XVALUE is too big.
//
//    Output, double ALNGAM, the logarithm of the gamma function of X.
//
{
  double alr2pi = 0.918938533204673;
  double r1[9] = {
    -2.66685511495, 
    -24.4387534237, 
    -21.9698958928, 
     11.1667541262, 
     3.13060547623, 
     0.607771387771, 
     11.9400905721, 
     31.4690115749, 
     15.2346874070 };
  double r2[9] = {
    -78.3359299449, 
    -142.046296688, 
     137.519416416, 
     78.6994924154, 
     4.16438922228, 
     47.0668766060, 
     313.399215894, 
     263.505074721, 
     43.3400022514 };
  double r3[9] = {
    -2.12159572323E+05, 
     2.30661510616E+05, 
     2.74647644705E+04, 
    -4.02621119975E+04, 
    -2.29660729780E+03, 
    -1.16328495004E+05, 
    -1.46025937511E+05, 
    -2.42357409629E+04, 
    -5.70691009324E+02 };
  double r4[5] = {
     0.279195317918525, 
     0.4917317610505968, 
     0.0692910599291889, 
     3.350343815022304, 
     6.012459259764103 };
  double value;
  double x;
  double x1;
  double x2;
  double xlge = 510000.0;
  double xlgst = 1.0E+30;
  double y;

  x = xvalue;
  value = 0.0;
//
//  Check the input.
//
  if ( xlgst <= x )
  {
    *ifault = 2;
    return value;
  }

  if ( x <= 0.0 )
  {
    *ifault = 1;
    return value;
  }

  *ifault = 0;
//
//  Calculation for 0 < X < 0.5 and 0.5 <= X < 1.5 combined.
//
  if ( x < 1.5 )
  {
    if ( x < 0.5 )
    {
      value = - log ( x );
      y = x + 1.0;
//
//  Test whether X < machine epsilon.
//
      if ( y == 1.0 )
      {
        return value;
      }
    }
    else
    {
      value = 0.0;
      y = x;
      x = ( x - 0.5 ) - 0.5;
    }

    value = value + x * (((( 
        r1[4]   * y 
      + r1[3] ) * y 
      + r1[2] ) * y 
      + r1[1] ) * y 
      + r1[0] ) / (((( 
                  y 
      + r1[8] ) * y 
      + r1[7] ) * y 
      + r1[6] ) * y 
      + r1[5] );

    return value;
  }
//
//  Calculation for 1.5 <= X < 4.0.
//
  if ( x < 4.0 )
  {
    y = ( x - 1.0 ) - 1.0;

    value = y * (((( 
        r2[4]   * x 
      + r2[3] ) * x 
      + r2[2] ) * x 
      + r2[1] ) * x 
      + r2[0] ) / (((( 
                  x 
      + r2[8] ) * x 
      + r2[7] ) * x 
      + r2[6] ) * x 
      + r2[5] );
  }
//
//  Calculation for 4.0 <= X < 12.0.
//
  else if ( x < 12.0 ) 
  {
    value = (((( 
        r3[4]   * x 
      + r3[3] ) * x 
      + r3[2] ) * x 
      + r3[1] ) * x 
      + r3[0] ) / (((( 
                  x 
      + r3[8] ) * x 
      + r3[7] ) * x 
      + r3[6] ) * x 
      + r3[5] );
  }
//
//  Calculation for 12.0 <= X.
//
  else
  {
    y = log ( x );
    value = x * ( y - 1.0 ) - 0.5 * y + alr2pi;

    if ( x <= xlge )
    {
      x1 = 1.0 / x;
      x2 = x1 * x1;

      value = value + x1 * ( ( 
             r4[2]   * 
        x2 + r4[1] ) * 
        x2 + r4[0] ) / ( ( 
        x2 + r4[4] ) * 
        x2 + r4[3] );
    }
  }

  return value;
}


//****************************************************************************80

double alnorm ( double x, bool upper )

//****************************************************************************80
//
//  Purpose:
//
//    ALNORM computes the cumulative density of the standard normal distribution.
//
//  Modified:
//
//    17 January 2008
//
//  Author:
//
//    David Hill
//    C++ version by John Burkardt
//
//  Reference:
//
//    David Hill,
//    Algorithm AS 66:
//    The Normal Integral,
//    Applied Statistics,
//    Volume 22, Number 3, 1973, pages 424-427.
//
//  Parameters:
//
//    Input, double X, is one endpoint of the semi-infinite interval
//    over which the integration takes place.
//
//    Input, bool UPPER, determines whether the upper or lower
//    interval is to be integrated:
//    .TRUE.  => integrate from X to + Infinity;
//    .FALSE. => integrate from - Infinity to X.
//
//    Output, double ALNORM, the integral of the standard normal
//    distribution over the desired interval.
//
{
  double a1 = 5.75885480458;
  double a2 = 2.62433121679;
  double a3 = 5.92885724438;
  double b1 = -29.8213557807;
  double b2 = 48.6959930692;
  double c1 = -0.000000038052;
  double c2 = 0.000398064794;
  double c3 = -0.151679116635;
  double c4 = 4.8385912808;
  double c5 = 0.742380924027;
  double c6 = 3.99019417011;
  double con = 1.28;
  double d1 = 1.00000615302;
  double d2 = 1.98615381364;
  double d3 = 5.29330324926;
  double d4 = -15.1508972451;
  double d5 = 30.789933034;
  double ltone = 7.0;
  double p = 0.398942280444;
  double q = 0.39990348504;
  double r = 0.398942280385;
  bool up;
  double utzero = 18.66;
  double value;
  double y;
  double z;

  up = upper;
  z = x;

  if ( z < 0.0 )
  {
    up = !up;
    z = - z;
  }

  if ( ltone < z && ( ( !up ) || utzero < z ) )
  {
    if ( up )
    {
      value = 0.0;
    }
    else
    {
      value = 1.0;
    }
    return value;
  }

  y = 0.5 * z * z;

  if ( z <= con )
  {
    value = 0.5 - z * ( p - q * y 
      / ( y + a1 + b1 
      / ( y + a2 + b2 
      / ( y + a3 ))));
  }
  else
  {
    value = r * exp ( - y ) 
      / ( z + c1 + d1 
      / ( z + c2 + d2 
      / ( z + c3 + d3 
      / ( z + c4 + d4 
      / ( z + c5 + d5 
      / ( z + c6 ))))));
  }

  if ( !up )
  {
    value = 1.0 - value;
  }

  return value;
}
//****************************************************************************80

double betain ( double x, double p, double q, double beta, int *ifault )

//****************************************************************************80
//
//  Purpose:
//
//    BETAIN computes the incomplete Beta function ratio.
//
//  Modified:
//
//    23 January 2008
//
//  Author:
//
//    KL Majumder, GP Bhattacharjee
//    C++ version by John Burkardt
//
//  Reference:
//
//    KL Majumder, GP Bhattacharjee,
//    Algorithm AS 63:
//    The incomplete Beta Integral,
//    Applied Statistics,
//    Volume 22, Number 3, 1973, pages 409-411.
//
//  Parameters:
//
//    Input, double X, the argument, between 0 and 1.
//
//    Input, double P, Q, the parameters, which
//    must be positive.
//
//    Input, double BETA, the logarithm of the complete
//    beta function.
//
//    Output, int *IFAULT, error flag.
//    0, no error.
//    nonzero, an error occurred.
//
//    Output, double BETAIN, the value of the incomplete
//    Beta function ratio.
//
{
  double acu = 0.1E-14;
  double ai;
  // double betain;
  double cx;
  bool indx;
  int ns;
  double pp;
  double psq;
  double qq;
  double rx;
  double temp;
  double term;
  double value;
  double xx;

  value = x;
  *ifault = 0;
//
//  Check the input arguments.
//
  if ( p <= 0.0 || q <= 0.0 )
  {
    *ifault = 1;
    return value;
  }

  if ( x < 0.0 || 1.0 < x )
  {
    *ifault = 2;
    return value;
  }
//
//  Special cases.
//
  if ( x == 0.0 || x == 1.0 )
  {
    return value;
  }
//
//  Change tail if necessary and determine S.
//
  psq = p + q;
  cx = 1.0 - x;

  if ( p < psq * x )
  {
    xx = cx;
    cx = x;
    pp = q;
    qq = p;
    indx = TRUE;
  }
  else
  {
    xx = x;
    pp = p;
    qq = q;
    indx = FALSE;
  }

  term = 1.0;
  ai = 1.0;
  value = 1.0;
  ns = ( int ) ( qq + cx * psq );
//
//  Use the Soper reduction formula.
//
  rx = xx / cx;
  temp = qq - ai;
  if ( ns == 0 )
  {
    rx = xx;
  }

  for ( ; ; )
  {
    term = term * temp * rx / ( pp + ai );
    value = value + term;;
    temp = r8_abs ( term );

    if ( temp <= acu && temp <= acu * value )
    {
      value = value * exp ( pp * log ( xx ) 
      + ( qq - 1.0 ) * log ( cx ) - beta ) / pp;

      if ( indx )
      {
        value = 1.0 - value;
      }
      break;
    }

    ai = ai + 1.0;
    ns = ns - 1;

    if ( 0 <= ns )
    {
      temp = qq - ai;
      if ( ns == 0 )
      {
        rx = xx;
      }
    }
    else
    {
      temp = psq;
      psq = psq + 1.0;
    }
  }

  return value;
}
//****************************************************************************80

double r8_abs ( double x )

//****************************************************************************80
//
//  Purpose:
//
//    R8_ABS returns the absolute value of an R8.
//
//  Modified:
//
//    14 November 2006
//
//  Author:
//
//    John Burkardt
//
//  Parameters:
//
//    Input, double X, the quantity whose absolute value is desired.
//
//    Output, double R8_ABS, the absolute value of X.
//
{
  double value;

  if ( 0.0 <= x )
  {
    value = x;
  } 
  else
  {
    value = -x;
  }
  return value;
}
//****************************************************************************80

void student_noncentral_cdf_values ( int *n_data, int *df, double *lambda, 
  double *x, double *fx )

//****************************************************************************80
//
//  Purpose:
//
//    STUDENT_NONCENTRAL_CDF_VALUES returns values of the noncentral Student CDF.
//
//  Discussion:
//
//    In Mathematica, the function can be evaluated by:
//
//      Needs["Statistics`ContinuousDistributions`"]
//      dist = NoncentralStudentTDistribution [ df, lambda ]
//      CDF [ dist, x ]
//
//    Mathematica seems to have some difficulty computing this function
//    to the desired number of digits.
//
//  Modified:
//
//    01 September 2004
//
//  Author:
//
//    John Burkardt
//
//  Reference:
//
//    Milton Abramowitz, Irene Stegun,
//    Handbook of Mathematical Functions,
//    National Bureau of Standards, 1964,
//    ISBN: 0-486-61272-4,
//    LC: QA47.A34.
//
//    Stephen Wolfram,
//    The Mathematica Book,
//    Fourth Edition,
//    Cambridge University Press, 1999,
//    ISBN: 0-521-64314-7,
//    LC: QA76.95.W65.
//
//  Parameters:
//
//    Input/output, int *N_DATA.  The user sets N_DATA to 0 before the
//    first call.  On each call, the routine increments N_DATA by 1, and
//    returns the corresponding data; when there is no more data, the
//    output value of N_DATA will be 0 again.
//
//    Output, int *DF, double *LAMBDA, the parameters of the
//    function.
//
//    Output, double *X, the argument of the function.
//
//    Output, double *FX, the value of the function.
//
{
# define N_MAX 30

  int df_vec[N_MAX] = { 
     1,  2,  3, 
     1,  2,  3, 
     1,  2,  3, 
     1,  2,  3, 
     1,  2,  3, 
    15, 20, 25, 
     1,  2,  3, 
    10, 10, 10, 
    10, 10, 10, 
    10, 10, 10 };

  double fx_vec[N_MAX] = { 
     0.8975836176504333E+00,  
     0.9522670169E+00,  
     0.9711655571887813E+00,  
     0.8231218864E+00,  
     0.9049021510E+00,  
     0.9363471834E+00,  
     0.7301025986E+00,  
     0.8335594263E+00,  
     0.8774010255E+00,  
     0.5248571617E+00,  
     0.6293856597E+00,  
     0.6800271741E+00,  
     0.20590131975E+00,  
     0.2112148916E+00,  
     0.2074730718E+00,  
     0.9981130072E+00,  
     0.9994873850E+00,  
     0.9998391562E+00,  
     0.168610566972E+00,  
     0.16967950985E+00,  
     0.1701041003E+00,  
     0.9247683363E+00,  
     0.7483139269E+00,  
     0.4659802096E+00,  
     0.9761872541E+00,  
     0.8979689357E+00,  
     0.7181904627E+00,  
     0.9923658945E+00,  
     0.9610341649E+00,  
     0.8688007350E+00 };

  double lambda_vec[N_MAX] = { 
     0.0E+00,  
     0.0E+00,  
     0.0E+00,  
     0.5E+00,  
     0.5E+00,  
     0.5E+00,  
     1.0E+00,  
     1.0E+00,  
     1.0E+00,  
     2.0E+00,  
     2.0E+00,  
     2.0E+00,  
     4.0E+00,  
     4.0E+00,  
     4.0E+00,  
     7.0E+00,  
     7.0E+00,  
     7.0E+00,  
     1.0E+00,  
     1.0E+00,  
     1.0E+00,  
     2.0E+00,  
     3.0E+00,  
     4.0E+00,  
     2.0E+00,  
     3.0E+00,  
     4.0E+00,  
     2.0E+00,  
     3.0E+00,  
     4.0E+00 };

  double x_vec[N_MAX] = { 
      3.00E+00,  
      3.00E+00,  
      3.00E+00,  
      3.00E+00,  
      3.00E+00,  
      3.00E+00,  
      3.00E+00,  
      3.00E+00,  
      3.00E+00,  
      3.00E+00,  
      3.00E+00,  
      3.00E+00,  
      3.00E+00,  
      3.00E+00,  
      3.00E+00,  
     15.00E+00,  
     15.00E+00,  
     15.00E+00,  
      0.05E+00,  
      0.05E+00,  
      0.05E+00,  
      4.00E+00,  
      4.00E+00,  
      4.00E+00,  
      5.00E+00,  
      5.00E+00,  
      5.00E+00,  
      6.00E+00,  
      6.00E+00,  
      6.00E+00 };

  if ( *n_data < 0 )
  {
    *n_data = 0;
  }

  *n_data = *n_data + 1;

  if ( N_MAX < *n_data )
  {
    *n_data = 0;
    *df = 0;
    *lambda = 0.0;
    *x = 0.0;
    *fx = 0.0;
  }
  else
  {
    *df = df_vec[*n_data-1];
    *lambda = lambda_vec[*n_data-1];
    *x = x_vec[*n_data-1];
    *fx = fx_vec[*n_data-1];
  }

  return;
# undef N_MAX
}

//****************************************************************************80

double tnc ( double t, double df, double delta, int *ifault )

//****************************************************************************80
//
//// TNC computes the tail of the noncentral T distribution.
//
//  Discussion:
//
//    This routine computes the cumulative probability at T of the 
//    non-central T-distribution with DF degrees of freedom (which may 
//    be fractional) and non-centrality parameter DELTA.
//
//  Modified:
//
//    25 January 2008
//
//  Author:
//
//    Russell Lenth
//    C++ version by John Burkardt
//
//  Reference:
//
//    Russell Lenth,
//    Algorithm AS 243:
//    Cumulative Distribution Function of the Non-Central T Distribution,
//    Applied Statistics,
//    Volume 38, Number 1, 1989, pages 185-189.
//
//    William Guenther,
//    Evaluation of probabilities for the noncentral distributions and 
//    difference of two T-variables with a desk calculator,
//    Journal of Statistical Computation and Simulation, 
//    Volume 6, Number 3-4, 1978, pages 199-206.
//
//  Parameters:
//
//    Input, double T, the point whose cumulative probability
//    is desired.
//
//    Input, double DF, the number of degrees of freedom.
//
//    Input, double DELTA, the noncentrality parameter.
//
//    Output, int *IFAULT, error flag.
//    0, no error.
//    nonzero, an error occcurred.
//
//    Output, double TNC, the tail of the noncentral
//    T distribution.
//
{
  double a;
  double albeta;
  double alnrpi = 0.57236494292470008707;
  double b;
  double del;
  double en;
  double errbd;
  double errmax = 1.0E-10;
  double geven;
  double godd;
  double half;
  int itrmax = 100;
  double lambda;
  bool negdel;
  double one;
  double p;
  double q;
  double r2pi = 0.79788456080286535588;
  double rxb;
  double s;
  double tt;
  double two;
  double value;;
  double x;
  double xeven;
  double xodd;
  double zero;

  value = 0.0;

  if ( df <= 0.0 )
  {
    *ifault = 2;
    return value;
  }

  *ifault = 0;

  tt = t;
  del = delta;
  negdel = FALSE;

  if ( t < 0.0 )
  {
    negdel = TRUE;
    tt = - tt;
    del = - del;
  }
//
//  Initialize twin series.
//
  en = 1.0;
  x = t * t / ( t * t + df );

  if ( x <= 0.0 )
  {
    *ifault = 0;
    value = value + alnorm ( del, TRUE );

    if ( negdel )
    {
      value = 1.0 - value;
    }
    return value;
  }

  lambda = del * del;
  p = 0.5 * exp ( - 0.5 * lambda );
  q = r2pi * p * del;
  s = 0.5 - p;
  a = 0.5;
  b = 0.5 * df;
  rxb = pow ( 1.0 - x, b );
  albeta = alnrpi + alngam2 ( b, ifault ) - alngam2 ( a + b, ifault );
  xodd = betain ( x, a, b, albeta, ifault );
  godd = 2.0 * rxb * exp ( a * log ( x ) - albeta );
  xeven = 1.0 - rxb;
  geven = b * x * rxb;
  value = p * xodd + q * xeven;
//
//  Repeat until convergence.
//
  for ( ; ; )
  {
    a = a + 1.0;
    xodd = xodd - godd;
    xeven = xeven - geven;
    godd = godd * x * ( a + b - 1.0 ) / a;
    geven = geven * x * ( a + b - 0.5 ) / ( a + 0.5 );
    p = p * lambda / ( 2.0 * en );
    q = q * lambda / ( 2.0 * en + 1.0 );
    s = s - p;
    en = en + 1.0;
    value = value + p * xodd + q * xeven;
    errbd = 2.0 * s * ( xodd - godd );

    if ( errbd <= errmax ) 
    {
      *ifault = 0;
      break;
    }

    if ( itrmax < en )
    {
      *ifault = 1;
      break;
    }
  }

  value = value + alnorm ( del, TRUE );

  if ( negdel )
  {
    value = 1.0 - value;
  }

  return value;
}

      program test_temp_stations

!---- Triangulation using DTRIS2 of Geompack Fortran triangulation package ----

      implicit none
	 
      integer, parameter :: node_num_max = 2500
      integer, parameter :: dim_num = 2
      integer (kind=4 ) :: i,j,ii,io,node_num,triangle_num
      integer (kind=4 ), dimension (3,node_num_max*2) :: triangle_neighbor
      integer (kind=4 ), dimension (3,node_num_max*2) :: triangle_node
      real ( kind = 8 ), dimension (dim_num,node_num_max) :: node_xy
      real ( kind = 8 ), dimension (node_num_max) :: rr
	 

!----  Read data from file "rr.par" ----
	 
      open(1,file='rr.par',status='old')
      do j=1,10000
        read(1,*,iostat=io)(node_xy(i,j),i=1,2),rr(j)
        if(io<0) exit		 
        write(99,*)(node_xy(i,j),i=1,2),rr(j)
      enddo
      close(1)
      node_num=j-1
      write(99,*)'Number of nodes = ', node_num
      write(*,*)'NUMBER OF STATIONS USED FOR TRIANGULATION = ', node_num          	   
	  
!----  Write control output to screen and to log file ----
	   
      write ( *, '(a)' ) ' '
      write ( *, '(a)' ) '  DTRIS2 computes the Delaunay triangulation of'
      write ( *, '(a)' ) '    a pointset in 2D.'
      write (99, '(a)' ) ' '
      write (99, '(a)' ) '  DTRIS2 computes the Delaunay triangulation of'
      write (99, '(a)' ) '    a pointset in 2D.'	   
	 
!----  Run the Delaunay triangulation ----

      call dtris2(node_num,node_xy,triangle_num,triangle_node,triangle_neighbor)
	 
      write(99,*)'Number of nodes = ', node_num
      write(99,*)'TRIANGLE NODES:'
      do j=1,node_num
	    write(99,*) (node_xy(i,j),i=1,2)
      enddo
      write(99,*)triangle_num, ' Triangles altogether'
	  
!---- Write triangle vertices and triangle nodes to files "triangle_vertices.xyz" and "triangle_nodes.dat" ----
	 
      open(1,file='triangle_nodes.dat')
      open(2,file='triangle_vertices.xyz')	  
      do j=1,triangle_num ! --> Make sure to use only triangles where all sides are shorter than 350 kilometres
        if((node_xy(1,triangle_node(1,j))-node_xy(1,triangle_node(2,j)))**2&
             &+(node_xy(2,triangle_node(1,j))-node_xy(2,triangle_node(2,j)))**2<=350000.**2) then
        if((node_xy(1,triangle_node(1,j))-node_xy(1,triangle_node(3,j)))**2&
             &+(node_xy(2,triangle_node(1,j))-node_xy(2,triangle_node(3,j)))**2<=350000.**2) then
        if((node_xy(1,triangle_node(3,j))-node_xy(1,triangle_node(2,j)))**2&
             &+(node_xy(2,triangle_node(3,j))-node_xy(2,triangle_node(2,j)))**2<=350000.**2) then
	      write(1,*)(triangle_node(i,j),i=1,3)	  
	      write(2,*)(node_xy(ii,triangle_node(1,j)),ii=1,2)
	      write(2,*)(node_xy(ii,triangle_node(2,j)),ii=1,2)
	      write(2,*)(node_xy(ii,triangle_node(3,j)),ii=1,2)
	      write(2,*)(node_xy(ii,triangle_node(1,j)),ii=1,2)
	      write(2,*)
        endif		 
        endif		 		
        endif		 		
      enddo
      close(1)
      close(2)	
!      include 'geompack1.f90'
      end program test_temp_stations
	 
	 
subroutine dtris2 ( node_num, node_xy, triangle_num, triangle_node, &
     triangle_neighbor)

  !*****************************************************************************80
  !
  !! DTRIS2 constructs a Delaunay triangulation of 2D vertices.
  !
  !  Discussion:
  !
  !    The routine constructs the Delaunay triangulation of a set of 2D vertices
  !    using an incremental approach and diagonal edge swaps.  Vertices are
  !    first sorted in lexicographically increasing (X,Y) order, and
  !    then are inserted one at a time from outside the convex hull.
  !
  !  Modified:
  !
  !    25 August 2001
  !
  !  Author:
  !
  !    Barry Joe,
  !    Department of Computing Science,
  !    University of Alberta,
  !    Edmonton, Alberta, Canada  T6G 2H1
  !
  !  Reference:
  !
  !    Barry Joe,
  !    GEOMPACK - a software package for the generation of meshes
  !    using geometric algorithms,
  !    Advances in Engineering Software,
  !    Volume 13, pages 325-331, 1991.
  !
  !  Parameters:
  !
  !    Input, integer NODE_NUM, the number of vertices.
  !
  !    Input/output, real ( kind = 8 ) NODE_XY(2,NODE_NUM), the coordinates
  !    of the vertices.  On output, the vertices have been sorted into
  !    dictionary order.
  !
  !    Output, integer TRIANGLE_NUM, the number of triangles in the triangulation;
  !    TRIANGLE_NUM is equal to 2*NODE_NUM - NB - 2, where NB is the number
  !    of boundary vertices.
  !
  !    Output, integer TRIANGLE_NODE(3,TRIANGLE_NUM), the nodes that make up 
  !    each triangle.  The elements are indices of P.  The vertices of the
  !    triangles are in counter clockwise order.
  !
  !    Output, integer TRIANGLE_NEIGHBOR(3,TRIANGLE_NUM), the triangle neighbor
  !    list.  Positive elements are indices of TIL; negative elements are used
  !    for links of a counter clockwise linked list of boundary edges;
  !    LINK = -(3*I + J-1) where I, J = triangle, edge index;
  !    TRIANGLE_NEIGHBOR(J,I) refers to the neighbor along edge from vertex J
  !    to J+1 (mod 3).
  !
  implicit none

  integer node_num
  integer, parameter :: node_num_max = 2000

  real ( kind = 8 ) cmax
  integer e
  integer i
  integer ierr
  integer indx(node_num)
  integer j
  integer k
  integer l
  integer ledg
  integer lr
  integer lrline
  integer ltri
  integer m
  integer m1
  integer m2
  integer n
  real ( kind = 8 ) node_xy(2,node_num_max)       
  integer redg
  integer rtri
  integer stack(node_num)
  integer t
  real ( kind = 8 ) tol
  integer top
  integer triangle_neighbor(3,node_num_max*2)
  integer triangle_num
  integer triangle_node(3,node_num_max*2)

12345 continue  

  tol = 100.0D+00 * epsilon ( tol )

  ierr = 0
  !
  !  Sort the vertices by increasing (x,y).
  !
  call r82vec_sort_heap_index_a ( node_num, node_xy, indx )

  call r82vec_permute ( node_num, node_xy, indx )
  !
  !  Make sure that the data points are "reasonably" distinct.
  !
  m1 = 1

  do i = 2, node_num

     m = m1
     m1 = i

     k = 0

     do j = 1, 2

        cmax = max ( abs ( node_xy(j,m) ), abs ( node_xy(j,m1) ) )

        if ( tol * ( cmax + 1.0D+00 ) &
             < abs ( node_xy(j,m) - node_xy(j,m1) ) ) then
           k = j
           exit
        end if

     end do

     if ( k == 0 ) then
        write ( *, '(a)' ) ' '
        write ( *, '(a)' ) 'DTRIS2 - Fatal error!'
        write ( *, '(a,i8)' ) '  Fails for point number I = ', i
        write ( *, '(a,i8)' ) '  M = ', m
        write ( *, '(a,i8)' ) '  M1 = ', m1
        write ( *, '(a,2g14.6)' ) '  X,Y(M)  = ', node_xy(1:2,m)
        write ( *, '(a,2g14.6)' ) '  X,Y(M1) = ', node_xy(1:2,m1)
        node_xy(1,m1)=node_xy(1,m1)+1. ! NB Station occurring twice!!! --> Add one meter to x coordinate and go back to beginning of routine! (Matthias Mohr, Oslo, Nov 2008)
        ierr = 224
        !return
        goto 12345	  
     end if

  end do
  !
  !  Starting from points M1 and M2, search for a third point M that
  !  makes a "healthy" triangle (M1,M2,M)
  !
  m1 = 1
  m2 = 2
  j = 3

  do

     if ( node_num < j ) then
        write ( *, '(a)' ) ' '
        write ( *, '(a)' ) 'DTRIS2 - Fatal error!'
        ierr = 225
        return
     end if

     m = j

     lr = lrline ( node_xy(1,m), node_xy(2,m), node_xy(1,m1), &
          node_xy(2,m1), node_xy(1,m2), node_xy(2,m2), 0.0D+00 )

     if ( lr /= 0 ) then
        exit
     end if

     j = j + 1

  end do
  !
  !  Set up the triangle information for (M1,M2,M), and for any other
  !  triangles you created because points were collinear with M1, M2.
  !
  triangle_num = j - 2

  if ( lr == -1 ) then

     triangle_node(1,1) = m1
     triangle_node(2,1) = m2
     triangle_node(3,1) = m
     triangle_neighbor(3,1) = -3

     do i = 2, triangle_num

        m1 = m2
        m2 = i+1
        triangle_node(1,i) = m1
        triangle_node(2,i) = m2
        triangle_node(3,i) = m
        triangle_neighbor(1,i-1) = -3 * i
        triangle_neighbor(2,i-1) = i
        triangle_neighbor(3,i) = i - 1

     end do

     triangle_neighbor(1,triangle_num) = -3 * triangle_num - 1
     triangle_neighbor(2,triangle_num) = -5
     ledg = 2
     ltri = triangle_num

  else

     triangle_node(1,1) = m2
     triangle_node(2,1) = m1
     triangle_node(3,1) = m
     triangle_neighbor(1,1) = -4

     do i = 2, triangle_num
        m1 = m2
        m2 = i+1
        triangle_node(1,i) = m2
        triangle_node(2,i) = m1
        triangle_node(3,i) = m
        triangle_neighbor(3,i-1) = i
        triangle_neighbor(1,i) = -3 * i - 3
        triangle_neighbor(2,i) = i - 1
     end do

     triangle_neighbor(3,triangle_num) = -3 * triangle_num
     triangle_neighbor(2,1) = -3 * triangle_num - 2
     ledg = 2
     ltri = 1

  end if
  !
  !  Insert the vertices one at a time from outside the convex hull,
  !  determine visible boundary edges, and apply diagonal edge swaps until
  !  Delaunay triangulation of vertices (so far) is obtained.
  !
  top = 0

  do i = j+1, node_num

     m = i
     m1 = triangle_node(ledg,ltri)

     if ( ledg <= 2 ) then
        m2 = triangle_node(ledg+1,ltri)
     else
        m2 = triangle_node(1,ltri)
     end if

     lr = lrline ( node_xy(1,m), node_xy(2,m), node_xy(1,m1), &
          node_xy(2,m1), node_xy(1,m2), node_xy(2,m2), 0.0D+00 )

     if ( 0 < lr ) then
        rtri = ltri
        redg = ledg
        ltri = 0
     else
        l = -triangle_neighbor(ledg,ltri)
        rtri = l / 3
        redg = mod(l,3) + 1
     end if

     call vbedg ( node_xy(1,m), node_xy(2,m), node_num, node_xy, triangle_num, &
          triangle_node, triangle_neighbor, ltri, ledg, rtri, redg )

     n = triangle_num + 1
     l = -triangle_neighbor(ledg,ltri)

     do

        t = l / 3
        e = mod ( l, 3 ) + 1
        l = -triangle_neighbor(e,t)
        m2 = triangle_node(e,t)

        if ( e <= 2 ) then
           m1 = triangle_node(e+1,t)
        else
           m1 = triangle_node(1,t)
        end if

        triangle_num = triangle_num + 1
        triangle_neighbor(e,t) = triangle_num
        triangle_node(1,triangle_num) = m1
        triangle_node(2,triangle_num) = m2
        triangle_node(3,triangle_num) = m
        triangle_neighbor(1,triangle_num) = t
        triangle_neighbor(2,triangle_num) = triangle_num - 1
        triangle_neighbor(3,triangle_num) = triangle_num + 1
        top = top + 1

        if ( node_num < top ) then
           ierr = 8
           write ( *, '(a)' ) ' '
           write ( *, '(a)' ) 'DTRIS2 - Fatal error!'
           write ( *, '(a)' ) '  Stack overflow.'
           return
        end if

        stack(top) = triangle_num

        if ( t == rtri .and. e == redg ) then
           exit
        end if

     end do

     triangle_neighbor(ledg,ltri) = -3 * n - 1
     triangle_neighbor(2,n) = -3 * triangle_num - 2
     triangle_neighbor(3,triangle_num) = -l
     ltri = n
     ledg = 2

     call swapec ( m, top, ltri, ledg, node_num, node_xy, triangle_num, &
          triangle_node, triangle_neighbor, stack, ierr )

     if ( ierr /= 0 ) then
        write ( *, '(a)' ) ' '
        write ( *, '(a)' ) 'DTRIS2 - Fatal error!'
        write ( *, '(a)' ) '  Error return from SWAPEC.'
        return
     end if

  end do
  !
  !  Now account for the sorting that we did.
  !
  do i = 1, 3
     do j = 1, triangle_num
        triangle_node(i,j) = indx ( triangle_node(i,j) )
     end do
  end do

  call perm_inv ( node_num, indx )

  call r82vec_permute ( node_num, node_xy, indx )

  return
end subroutine dtris2


function diaedg ( x0, y0, x1, y1, x2, y2, x3, y3 )

  !*****************************************************************************80
  !
  !! DIAEDG chooses a diagonal edge.
  !
  !  Discussion:
  !
  !    The routine determines whether 0--2 or 1--3 is the diagonal edge
  !    that should be chosen, based on the circumcircle criterion, where
  !    (X0,Y0), (X1,Y1), (X2,Y2), (X3,Y3) are the vertices of a simple
  !    quadrilateral in counterclockwise order.
  !
  !  Modified:
  !
  !    19 February 2001
  !
  !  Author:
  !
  !    Barry Joe,
  !    Department of Computing Science,
  !    University of Alberta,
  !    Edmonton, Alberta, Canada  T6G 2H1
  !
  !  Reference:
  !
  !    Barry Joe,
  !    GEOMPACK - a software package for the generation of meshes
  !    using geometric algorithms,
  !    Advances in Engineering Software,
  !    Volume 13, pages 325-331, 1991.
  !
  !  Parameters:
  !
  !    Input, real ( kind = 8 ) X0, Y0, X1, Y1, X2, Y2, X3, Y3, the
  !    coordinates of the vertices of a quadrilateral, given in
  !    counter clockwise order.
  !
  !    Output, integer DIAEDG, chooses a diagonal:
  !    +1, if diagonal edge 02 is chosen;
  !    -1, if diagonal edge 13 is chosen;
  !     0, if the four vertices are cocircular.
  !
  implicit none

  real ( kind = 8 ) ca
  real ( kind = 8 ) cb
  integer diaedg
  real ( kind = 8 ) dx10
  real ( kind = 8 ) dx12
  real ( kind = 8 ) dx30
  real ( kind = 8 ) dx32
  real ( kind = 8 ) dy10
  real ( kind = 8 ) dy12
  real ( kind = 8 ) dy30
  real ( kind = 8 ) dy32
  real ( kind = 8 ) s
  real ( kind = 8 ) tol
  real ( kind = 8 ) tola
  real ( kind = 8 ) tolb
  real ( kind = 8 ) x0
  real ( kind = 8 ) x1
  real ( kind = 8 ) x2
  real ( kind = 8 ) x3
  real ( kind = 8 ) y0
  real ( kind = 8 ) y1
  real ( kind = 8 ) y2
  real ( kind = 8 ) y3

  tol = 100.0D+00 * epsilon ( tol )

  dx10 = x1 - x0
  dy10 = y1 - y0
  dx12 = x1 - x2
  dy12 = y1 - y2
  dx30 = x3 - x0
  dy30 = y3 - y0
  dx32 = x3 - x2
  dy32 = y3 - y2

  tola = tol * max ( abs ( dx10 ), abs ( dy10 ), abs ( dx30 ), abs ( dy30 ) )
  tolb = tol * max ( abs ( dx12 ), abs ( dy12 ), abs ( dx32 ), abs ( dy32 ) )

  ca = dx10 * dx30 + dy10 * dy30
  cb = dx12 * dx32 + dy12 * dy32

  if ( tola < ca .and. tolb < cb ) then

     diaedg = -1

  else if ( ca < -tola .and. cb < -tolb ) then

     diaedg = 1

  else

     tola = max ( tola, tolb )
     s = ( dx10 * dy30 - dx30 * dy10 ) * cb + ( dx32 * dy12 - dx12 * dy32 ) * ca

     if ( tola < s ) then
        diaedg = -1
     else if ( s < -tola ) then
        diaedg = 1
     else
        diaedg = 0
     end if

  end if

  return
end function diaedg

subroutine get_unit ( iunit )

  !*****************************************************************************80
  !
  !! GET_UNIT returns a free FORTRAN unit number.
  !
  !  Discussion:
  !
  !    A "free" FORTRAN unit number is an integer between 1 and 99 which
  !    is not currently associated with an I/O device.  A free FORTRAN unit
  !    number is needed in order to open a file with the OPEN command.
  !
  !    If IUNIT = 0, then no free FORTRAN unit could be found, although
  !    all 99 units were checked (except for units 5, 6 and 9, which
  !    are commonly reserved for console I/O).
  !
  !    Otherwise, IUNIT is an integer between 1 and 99, representing a
  !    free FORTRAN unit.  Note that GET_UNIT assumes that units 5 and 6
  !    are special, and will never return those values.
  !
  !  Modified:
  !
  !    18 September 2005
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Output, integer IUNIT, the free unit number.
  !
  implicit none

  integer i
  integer ios
  integer iunit
  logical lopen

  iunit = 0

  do i = 1, 99

     if ( i /= 5 .and. i /= 6 .and. i /= 9 ) then

        inquire ( unit = i, opened = lopen, iostat = ios )

        if ( ios == 0 ) then
           if ( .not. lopen ) then
              iunit = i
              return
           end if
        end if

     end if

  end do

  return
end subroutine get_unit
function i4_modp ( i, j )

  !*****************************************************************************80
  !
  !! I4_MODP returns the nonnegative remainder of integer division.
  !
  !  Formula:
  !
  !    If
  !      NREM = I4_MODP ( I, J )
  !      NMULT = ( I - NREM ) / J
  !    then
  !      I = J * NMULT + NREM
  !    where NREM is always nonnegative.
  !
  !  Discussion:
  !
  !    The MOD function computes a result with the same sign as the
  !    quantity being divided.  Thus, suppose you had an angle A,
  !    and you wanted to ensure that it was between 0 and 360.
  !    Then mod(A,360) would do, if A was positive, but if A
  !    was negative, your result would be between -360 and 0.
  !
  !    On the other hand, I4_MODP(A,360) is between 0 and 360, always.
  !
  !  Examples:
  !
  !        I     J     MOD  I4_MODP    Factorization
  !
  !      107    50       7       7    107 =  2 *  50 + 7
  !      107   -50       7       7    107 = -2 * -50 + 7
  !     -107    50      -7      43   -107 = -3 *  50 + 43
  !     -107   -50      -7      43   -107 =  3 * -50 + 43
  !
  !  Modified:
  !
  !    02 March 1999
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer I, the number to be divided.
  !
  !    Input, integer J, the number that divides I.
  !
  !    Output, integer I4_MODP, the nonnegative remainder when I is
  !    divided by J.
  !
  implicit none

  integer i
  integer i4_modp
  integer j

  if ( j == 0 ) then
     write ( *, '(a)' ) ' '
     write ( *, '(a)' ) 'I4_MODP - Fatal error!'
     write ( *, '(a,i8)' ) '  I4_MODP ( I, J ) called with J = ', j
     stop
  end if

  i4_modp = mod ( i, j )

  if ( i4_modp < 0 ) then
     i4_modp = i4_modp + abs ( j )
  end if

  return
end function i4_modp
subroutine i4_swap ( i, j )

  !*****************************************************************************80
  !
  !! I4_SWAP swaps two integer values.
  !
  !  Modified:
  !
  !    30 November 1998
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input/output, integer I, J.  On output, the values of I and
  !    J have been interchanged.
  !
  implicit none

  integer i
  integer j
  integer k

  k = i
  i = j
  j = k

  return
end subroutine i4_swap
function i4_wrap ( ival, ilo, ihi )

  !*****************************************************************************80
  !
  !! I4_WRAP forces an integer to lie between given limits by wrapping.
  !
  !  Example:
  !
  !    ILO = 4, IHI = 8
  !
  !    I  I4_WRAP
  !
  !    -2     8
  !    -1     4
  !     0     5
  !     1     6
  !     2     7
  !     3     8
  !     4     4
  !     5     5
  !     6     6
  !     7     7
  !     8     8
  !     9     4
  !    10     5
  !    11     6
  !    12     7
  !    13     8
  !    14     4
  !
  !  Modified:
  !
  !    19 August 2003
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer IVAL, an integer value.
  !
  !    Input, integer ILO, IHI, the desired bounds for the integer value.
  !
  !    Output, integer I4_WRAP, a "wrapped" version of IVAL.
  !
  implicit none

  integer i4_modp
  integer i4_wrap
  integer ihi
  integer ilo
  integer ival
  integer jhi
  integer jlo
  integer wide

  jlo = min ( ilo, ihi )
  jhi = max ( ilo, ihi )

  wide = jhi - jlo + 1

  if ( wide == 1 ) then
     i4_wrap = jlo
  else
     i4_wrap = jlo + i4_modp ( ival - jlo, wide )
  end if

  return
end function i4_wrap
subroutine i4mat_transpose_print ( m, n, a, title )

  !*****************************************************************************80
  !
  !! I4MAT_TRANSPOSE_PRINT prints an I4MAT, transposed.
  !
  !  Modified:
  !
  !    09 February 2005
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer M, N, the number of rows and columns.
  !
  !    Input, integer A(M,N), an M by N matrix to be printed.
  !
  !    Input, character ( len = * ) TITLE, an optional title.
  !
  implicit none

  integer m
  integer n

  integer a(m,n)
  character ( len = * ) title

  call i4mat_transpose_print_some ( m, n, a, 1, 1, m, n, title )

  return
end subroutine i4mat_transpose_print
subroutine i4mat_transpose_print_some ( m, n, a, ilo, jlo, ihi, jhi, title )

  !*****************************************************************************80
  !
  !! I4MAT_TRANSPOSE_PRINT_SOME prints some of the transpose of an I4MAT.
  !
  !  Modified:
  !
  !    09 February 2005
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer M, N, the number of rows and columns.
  !
  !    Input, integer A(M,N), an M by N matrix to be printed.
  !
  !    Input, integer ILO, JLO, the first row and column to print.
  !
  !    Input, integer IHI, JHI, the last row and column to print.
  !
  !    Input, character ( len = * ) TITLE, an optional title.
  !
  implicit none

  integer, parameter :: incx = 10
  integer m
  integer n

  integer a(m,n)
  character ( len = 7 ) ctemp(incx)
  integer i
  integer i2
  integer i2hi
  integer i2lo
  integer ihi
  integer ilo
  integer inc
  integer j
  integer j2hi
  integer j2lo
  integer jhi
  integer jlo
  character ( len = * ) title

  if ( 0 < len_trim ( title ) ) then
     write ( *, '(a)' ) ' '
     write ( *, '(a)' ) trim ( title )
  end if

  do i2lo = max ( ilo, 1 ), min ( ihi, m ), incx

     i2hi = i2lo + incx - 1
     i2hi = min ( i2hi, m )
     i2hi = min ( i2hi, ihi )

     inc = i2hi + 1 - i2lo

     write ( *, '(a)' ) ' '

     do i = i2lo, i2hi
        i2 = i + 1 - i2lo
        write ( ctemp(i2), '(i7)') i
     end do

     write ( *, '(''  Row '',10a7)' ) ctemp(1:inc)
     write ( *, '(a)' ) '  Col'
     write ( *, '(a)' ) ' '

     j2lo = max ( jlo, 1 )
     j2hi = min ( jhi, n )

     do j = j2lo, j2hi

        do i2 = 1, inc

           i = i2lo - 1 + i2

           write ( ctemp(i2), '(i7)' ) a(i,j)

        end do

        write ( *, '(i5,1x,10a7)' ) j, ( ctemp(i), i = 1, inc )

     end do

  end do

  write ( *, '(a)' ) ' '

  return
end subroutine i4mat_transpose_print_some
subroutine i4vec_heap_d ( n, a )

  !*****************************************************************************80
  !
  !! I4VEC_HEAP_D reorders an I4VEC into an descending heap.
  !
  !  Discussion:
  !
  !    A descending heap is an array A with the property that, for every index J,
  !    A(J) >= A(2*J) and A(J) >= A(2*J+1), (as long as the indices
  !    2*J and 2*J+1 are legal).
  !
  !                  A(1)
  !                /      \
  !            A(2)         A(3)
  !          /     \        /  \
  !      A(4)       A(5)  A(6) A(7)
  !      /  \       /   \
  !    A(8) A(9) A(10) A(11)
  !
  !  Modified:
  !
  !    15 April 1999
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Reference:
  !
  !    A Nijenhuis and H Wilf,
  !    Combinatorial Algorithms,
  !    Academic Press, 1978, second edition,
  !    ISBN 0-12-519260-6.
  !
  !  Parameters:
  !
  !    Input, integer N, the size of the input array.
  !
  !    Input/output, integer A(N).
  !    On input, an unsorted array.
  !    On output, the array has been reordered into a heap.
  !
  implicit none

  integer n

  integer a(n)
  integer i
  integer ifree
  integer key
  integer m
  !
  !  Only nodes N/2 down to 1 can be "parent" nodes.
  !
  do i = n/2, 1, -1
     !
     !  Copy the value out of the parent node.
     !  Position IFREE is now "open".
     !
     key = a(i)
     ifree = i

     do
        !
        !  Positions 2*IFREE and 2*IFREE + 1 are the descendants of position
        !  IFREE.  (One or both may not exist because they exceed N.)
        !
        m = 2 * ifree
        !
        !  Does the first position exist?
        !
        if ( n < m ) then
           exit
        end if
        !
        !  Does the second position exist?
        !
        if ( m + 1 <= n ) then
           !
           !  If both positions exist, take the larger of the two values,
           !  and update M if necessary.
           !
           if ( a(m) < a(m+1) ) then
              m = m + 1
           end if

        end if
        !
        !  If the large descendant is larger than KEY, move it up,
        !  and update IFREE, the location of the free position, and
        !  consider the descendants of THIS position.
        !
        if ( a(m) <= key ) then
           exit
        end if

        a(ifree) = a(m)
        ifree = m

     end do
     !
     !  Once there is no more shifting to do, KEY moves into the free spot IFREE.
     !
     a(ifree) = key

  end do

  return
end subroutine i4vec_heap_d
subroutine i4vec_sort_heap_a ( n, a )

  !*****************************************************************************80
  !
  !! I4VEC_SORT_HEAP_A ascending sorts an I4VEC using heap sort.
  !
  !  Modified:
  !
  !    15 April 1999
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Reference:
  !
  !    A Nijenhuis and H Wilf,
  !    Combinatorial Algorithms,
  !    Academic Press, 1978, second edition,
  !    ISBN 0-12-519260-6.
  !
  !  Parameters:
  !
  !    Input, integer N, the number of entries in the array.
  !
  !    Input/output, integer A(N).
  !    On input, the array to be sorted;
  !    On output, the array has been sorted.
  !
  implicit none

  integer n

  integer a(n)
  integer n1

  if ( n <= 1 ) then
     return
  end if
  !
  !  1: Put A into descending heap form.
  !
  call i4vec_heap_d ( n, a )
  !
  !  2: Sort A.
  !
  !  The largest object in the heap is in A(1).
  !  Move it to position A(N).
  !
  call i4_swap ( a(1), a(n) )
  !
  !  Consider the diminished heap of size N1.
  !
  do n1 = n-1, 2, -1
     !
     !  Restore the heap structure of A(1) through A(N1).
     !
     call i4vec_heap_d ( n1, a )
     !
     !  Take the largest object from A(1) and move it to A(N1).
     !
     call i4_swap ( a(1), a(n1) )

  end do

  return
end subroutine i4vec_sort_heap_a
subroutine i4vec_sorted_unique ( n, a, nuniq )

  !*****************************************************************************80
  !
  !! I4VEC_SORTED_UNIQUE finds the unique elements in a sorted I4VEC.
  !
  !  Modified:
  !
  !    09 July 2000
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer N, the number of elements in A.
  !
  !    Input/output, integer A(N).  On input, the sorted
  !    integer array.  On output, the unique elements in A.
  !
  !    Output, integer NUNIQ, the number of unique elements in A.
  !
  implicit none

  integer n

  integer a(n)
  integer itest
  integer nuniq

  nuniq = 0

  if ( n <= 0 ) then
     return
  end if

  nuniq = 1

  do itest = 2, n

     if ( a(itest) /= a(nuniq) ) then
        nuniq = nuniq + 1
        a(nuniq) = a(itest)
     end if

  end do

  return
end subroutine i4vec_sorted_unique
function lrline ( xu, yu, xv1, yv1, xv2, yv2, dv )

  !*****************************************************************************80
  !
  !! LRLINE determines if a point is left of, right or, or on a directed line.
  !
  !  Discussion:
  !
  !    The directed line is parallel to, and at a signed distance DV from
  !    a directed base line from (XV1,YV1) to (XV2,YV2).
  !
  !  Modified:
  !
  !    14 July 2001
  !
  !  Author:
  !
  !    Barry Joe,
  !    Department of Computing Science,
  !    University of Alberta,
  !    Edmonton, Alberta, Canada  T6G 2H1
  !
  !  Reference:
  !
  !    Barry Joe,
  !    GEOMPACK - a software package for the generation of meshes
  !    using geometric algorithms,
  !    Advances in Engineering Software,
  !    Volume 13, pages 325-331, 1991.
  !
  !  Parameters:
  !
  !    Input, real ( kind = 8 ) XU, YU, the coordinates of the point whose
  !    position relative to the directed line is to be determined.
  !
  !    Input, real ( kind = 8 ) XV1, YV1, XV2, YV2, the coordinates of two points
  !    that determine the directed base line.
  !
  !    Input, real ( kind = 8 ) DV, the signed distance of the directed line
  !    from the directed base line through the points (XV1,YV1) and (XV2,YV2).
  !    DV is positive for a line to the left of the base line.
  !
  !    Output, integer LRLINE, the result:
  !    +1, the point is to the right of the directed line;
  !     0, the point is on the directed line;
  !    -1, the point is to the left of the directed line.
  !
  implicit none

  real ( kind = 8 ) dv
  real ( kind = 8 ) dx
  real ( kind = 8 ) dxu
  real ( kind = 8 ) dy
  real ( kind = 8 ) dyu
  integer lrline
  real ( kind = 8 ) t
  real ( kind = 8 ) tol
  real ( kind = 8 ) tolabs
  real ( kind = 8 ) xu
  real ( kind = 8 ) xv1
  real ( kind = 8 ) xv2
  real ( kind = 8 ) yu
  real ( kind = 8 ) yv1
  real ( kind = 8 ) yv2

  tol = 100.0D+00 * epsilon ( tol )

  dx = xv2 - xv1
  dy = yv2 - yv1
  dxu = xu - xv1
  dyu = yu - yv1

  tolabs = tol * max ( abs ( dx ), abs ( dy ), abs ( dxu ), &
       abs ( dyu ), abs ( dv ) )

  t = dy * dxu - dx * dyu + dv * sqrt ( dx * dx + dy * dy )

  if ( tolabs < t ) then
     lrline = 1
  else if ( -tolabs <= t ) then
     lrline = 0
  else
     lrline = -1
  end if

  return
end function lrline
subroutine perm_check ( n, p, ierror )

  !*****************************************************************************80
  !
  !! PERM_CHECK checks that a vector represents a permutation.
  !
  !  Discussion:
  !
  !    The routine verifies that each of the integers from 1
  !    to N occurs among the N entries of the permutation.
  !
  !  Modified:
  !
  !    01 February 2001
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer N, the number of entries.
  !
  !    Input, integer P(N), the array to check.
  !
  !    Output, integer IERROR, error flag.
  !    0, the array represents a permutation.
  !    nonzero, the array does not represent a permutation.  The smallest
  !    missing value is equal to IERROR.
  !
  implicit none

  integer n

  integer ierror
  integer ifind
  integer iseek
  integer p(n)

  ierror = 0

  do iseek = 1, n

     ierror = iseek

     do ifind = 1, n
        if ( p(ifind) == iseek ) then
           ierror = 0
           exit
        end if
     end do

     if ( ierror /= 0 ) then
        return
     end if

  end do

  return
end subroutine perm_check
subroutine perm_inv ( n, p )

  !*****************************************************************************80
  !
  !! PERM_INV inverts a permutation "in place".
  !
  !  Modified:
  !
  !    25 July 2000
  !
  !  Parameters:
  !
  !    Input, integer N, the number of objects being permuted.
  !
  !    Input/output, integer P(N), the permutation, in standard index form.
  !    On output, P describes the inverse permutation
  !
  implicit none

  integer n

  integer i
  integer i0
  integer i1
  integer i2
  integer ierror
  integer is
  integer p(n)

  if ( n <= 0 ) then
     write ( *, '(a)' ) ' '
     write ( *, '(a)' ) 'PERM_INV - Fatal error!'
     write ( *, '(a,i8)' ) '  Input value of N = ', n
     stop
  end if

  call perm_check ( n, p, ierror )

  if ( ierror /= 0 ) then
     write ( *, '(a)' ) ' '
     write ( *, '(a)' ) 'PERM_INV - Fatal error!'
     write ( *, '(a)' ) '  The input array does not represent'
     write ( *, '(a)' ) '  a proper permutation.  In particular, the'
     write ( *, '(a,i8)' ) '  array is missing the value ', ierror
     stop
  end if

  is = 1

  do i = 1, n

     i1 = p(i)

     do while ( i < i1 )
        i2 = p(i1)
        p(i1) = -i2
        i1 = i2
     end do

     is = -sign ( 1, p(i) )
     p(i) = sign ( p(i), is )

  end do

  do i = 1, n

     i1 = -p(i)

     if ( 0 <= i1 ) then

        i0 = i

        do

           i2 = p(i1)
           p(i1) = i0

           if ( i2 < 0 ) then
              exit
           end if

           i0 = i1
           i1 = i2

        end do

     end if

  end do

  return
end subroutine perm_inv
subroutine points_delaunay_naive_2d ( node_num, node_xy, maxtri, &
     triangle_num, triangle_node )

  !*****************************************************************************80
  !
  !! POINTS_DELAUNAY_NAIVE_2D is a naive Delaunay triangulation scheme.
  !
  !  Discussion:
  !
  !    This routine is only suitable as a demonstration code for small
  !    problems.  Its running time is of order NODE_NUM**4.  Much faster
  !    algorithms are available.
  !
  !    Given a set of nodes in the plane, a triangulation is set of
  !    triples of distinct nodes, forming triangles, so that every
  !    point within the convex hull of the set of nodes is either
  !    one of the nodes, or lies on an edge of one or more triangles,
  !    or lies within exactly one triangle.
  !
  !    A Delaunay triangulation is a triangulation with additional
  !    properties.
  !
  !    NODE_NUM must be at least 3.
  !
  !  Modified:
  !
  !    08 November 2000
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Reference:
  !
  !    Joseph O'Rourke,
  !    Computational Geometry,
  !    Cambridge University Press,
  !    Second Edition, 1998, page 187.
  !
  !  Parameters:
  !
  !    Input, integer NODE_NUM, the number of nodes.
  !
  !    Input, real ( kind = 8 ) NODE_XY(2,NODE_NUM), the coordinates of the nodes.
  !
  !    Input, integer MAXTRI, the maximum number of triangles.
  !
  !    Output, integer TRIANGLE_NUM, the number of triangles in the triangulation.
  !
  !    Output, integer TRIANGLE_NODE(3,MAXTRI), the indices of the triangle nodes.
  !
  implicit none

  integer, parameter :: dim_num = 2
  integer maxtri
  integer node_num

  logical flag
  integer i
  integer j
  integer k
  integer m
  real ( kind = 8 ) node_xy(dim_num,node_num)
  integer triangle_node(3,maxtri)
  integer triangle_num
  real ( kind = 8 ) xn
  real ( kind = 8 ) yn
  real ( kind = 8 ) z(node_num)
  real ( kind = 8 ) zn

  triangle_num = 0

  if ( node_num < 3 ) then
     return
  end if
  !
  !  Compute Z = X*X + Y*Y.
  !
  z(1:node_num) = node_xy(1,1:node_num)**2 + node_xy(2,1:node_num)**2
  !
  !  For each triple (I,J,K):
  !
  do i = 1, node_num - 2
     do j = i+1, node_num
        do k = i+1, node_num

           if ( j /= k ) then

              xn = ( node_xy(2,j) - node_xy(2,i) ) * ( z(k) - z(i) ) &
                   - ( node_xy(2,k) - node_xy(2,i) ) * ( z(j) - z(i) )

              yn = ( node_xy(1,k) - node_xy(1,i) ) * ( z(j) - z(i) ) &
                   - ( node_xy(1,j) - node_xy(1,i) ) * ( z(k) - z(i) )

              zn = ( node_xy(1,j) - node_xy(1,i) ) &
                   * ( node_xy(2,k) - node_xy(2,i) ) &
                   - ( node_xy(1,k) - node_xy(1,i) ) &
                   * ( node_xy(2,j) - node_xy(2,i) )

              flag = ( zn < 0.0D+00 )

              if ( flag ) then
                 do m = 1, node_num
                    flag = flag .and. &
                         ( ( node_xy(1,m) - node_xy(1,i) ) * xn &
                         + ( node_xy(2,m) - node_xy(2,i) ) * yn &
                         + ( z(m)   - z(i) )   * zn <= 0.0D+00 )
                 end do
              end if

              if ( flag ) then
                 if ( triangle_num < maxtri ) then
                    triangle_num = triangle_num + 1
                    triangle_node(1:3,triangle_num) = (/ i, j, k /)
                 end if
              end if

           end if

        end do
     end do
  end do

  return
end subroutine points_delaunay_naive_2d
subroutine r82vec_part_quick_a ( n, a, l, r )

  !*****************************************************************************80
  !
  !! R82VEC_PART_QUICK_A reorders an R82VEC as part of a quick sort.
  !
  !  Discussion:
  !
  !    The routine reorders the entries of A.  Using A(1:2,1) as a
  !    key, all entries of A that are less than or equal to the key will
  !    precede the key, which precedes all entries that are greater than the key.
  !
  !  Example:
  !
  !    Input:
  !
  !      N = 8
  !
  !      A = ( (2,4), (8,8), (6,2), (0,2), (10,6), (10,0), (0,6), (4,8) )
  !
  !    Output:
  !
  !      L = 2, R = 4
  !
  !      A = ( (0,2), (0,6), (2,4), (8,8), (6,2), (10,6), (10,0), (4,8) )
  !             -----------          ----------------------------------
  !             LEFT          KEY    RIGHT
  !
  !  Modified:
  !
  !    08 December 2004
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer N, the number of entries of A.
  !
  !    Input/output, real ( kind = 8 ) A(2,N).  On input, the array to be checked.
  !    On output, A has been reordered as described above.
  !
  !    Output, integer L, R, the indices of A that define the three segments.
  !    Let KEY = the input value of A(1:2,1).  Then
  !    I <= L                 A(1:2,I) < KEY;
  !         L < I < R         A(1:2,I) = KEY;
  !                 R <= I    KEY < A(1:2,I).
  !
  implicit none

  integer n
  integer, parameter :: dim_num = 2

  real ( kind = 8 ) a(dim_num,n)
  logical r8vec_eq
  logical r8vec_gt
  logical r8vec_lt
  integer i
  real ( kind = 8 ) key(dim_num)
  integer l
  integer m
  integer r

  if ( n < 1 ) then
     write ( *, '(a)' ) ' '
     write ( *, '(a)' ) 'R82VEC_PART_QUICK_A - Fatal error!'
     write ( *, '(a)' ) '  N < 1.'
     stop
  else if ( n == 1 ) then
     l = 0
     r = 2
     return
  end if

  key(1:dim_num) = a(1:dim_num,1)
  m = 1
  !
  !  The elements of unknown size have indices between L+1 and R-1.
  !
  l = 1
  r = n + 1

  do i = 2, n

     if ( r8vec_gt ( dim_num, a(1:dim_num,l+1), key(1:dim_num) ) ) then
        r = r - 1
        call r8vec_swap ( dim_num, a(1:dim_num,r), a(1:dim_num,l+1) )
     else if ( r8vec_eq ( dim_num, a(1:dim_num,l+1), key(1:dim_num) ) ) then
        m = m + 1
        call r8vec_swap ( dim_num, a(1:dim_num,m), a(1:dim_num,l+1) )
        l = l + 1
     else if ( r8vec_lt ( dim_num, a(1:dim_num,l+1), key(1:dim_num) ) ) then
        l = l + 1
     end if

  end do
  !
  !  Now shift small elements to the left, and KEY elements to center.
  !
  do i = 1, l - m
     a(1:dim_num,i) = a(1:dim_num,i+m)
  end do

  l = l - m

  do i = 1, dim_num
     a(i,l+1:l+m) = key(i)
  end do

  return
end subroutine r82vec_part_quick_a
subroutine r82vec_permute ( n, a, p )

  !*****************************************************************************80
  !
  !! R82VEC_PERMUTE permutes an R82VEC in place.
  !
  !  Discussion:
  !
  !    This routine permutes an array of real "objects", but the same
  !    logic can be used to permute an array of objects of any arithmetic
  !    type, or an array of objects of any complexity.  The only temporary
  !    storage required is enough to store a single object.  The number
  !    of data movements made is N + the number of cycles of order 2 or more,
  !    which is never more than N + N/2.
  !
  !  Example:
  !
  !    Input:
  !
  !      N = 5
  !      P = (   2,    4,    5,    1,    3 )
  !      A = ( 1.0,  2.0,  3.0,  4.0,  5.0 )
  !          (11.0, 22.0, 33.0, 44.0, 55.0 )
  !
  !    Output:
  !
  !      A    = (  2.0,  4.0,  5.0,  1.0,  3.0 )
  !             ( 22.0, 44.0, 55.0, 11.0, 33.0 ).
  !
  !  Modified:
  !
  !    08 December 2004
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer N, the number of objects.
  !
  !    Input/output, real ( kind = 8 ) A(2,N), the array to be permuted.
  !
  !    Input, integer P(N), the permutation.  P(I) = J means
  !    that the I-th element of the output array should be the J-th
  !    element of the input array.  P must be a legal permutation
  !    of the integers from 1 to N, otherwise the algorithm will
  !    fail catastrophically.
  !
  implicit none

  integer n

  real ( kind = 8 ) a(2,n)
  real ( kind = 8 ) a_temp(2)
  integer ierror
  integer iget
  integer iput
  integer istart
  integer p(n)

  call perm_check ( n, p, ierror )

  if ( ierror /= 0 ) then
     write ( *, '(a)' ) ' '
     write ( *, '(a)' ) 'R82VEC_PERMUTE - Fatal error!'
     write ( *, '(a)' ) '  The input array does not represent'
     write ( *, '(a)' ) '  a proper permutation.  In particular, the'
     write ( *, '(a,i8)' ) '  array is missing the value ', ierror
     stop
  end if
  !
  !  Search for the next element of the permutation that has not been used.
  !
  do istart = 1, n

     if ( p(istart) < 0 ) then

        cycle

     else if ( p(istart) == istart ) then

        p(istart) = -p(istart)
        cycle

     else

        a_temp(1:2) = a(1:2,istart)
        iget = istart
        !
        !  Copy the new value into the vacated entry.
        !
        do

           iput = iget
           iget = p(iget)

           p(iput) = -p(iput)

           if ( iget < 1 .or. n < iget ) then
              write ( *, '(a)' ) ' '
              write ( *, '(a)' ) 'R82VEC_PERMUTE - Fatal error!'
              stop
           end if

           if ( iget == istart ) then
              a(1:2,iput) = a_temp(1:2)
              exit
           end if

           a(1:2,iput) = a(1:2,iget)

        end do

     end if

  end do
  !
  !  Restore the signs of the entries.
  !
  p(1:n) = -p(1:n)

  return
end subroutine r82vec_permute
subroutine r82vec_sort_heap_index_a ( n, a, indx )

  !*****************************************************************************80
  !
  !! R82VEC_SORT_HEAP_INDEX_A does an indexed heap ascending sort of an R82VEC.
  !
  !  Discussion:
  !
  !    The sorting is not actually carried out.  Rather an index array is
  !    created which defines the sorting.  This array may be used to sort
  !    or index the array, or to sort or index related arrays keyed on the
  !    original array.
  !
  !    Once the index array is computed, the sorting can be carried out
  !    "implicitly:
  !
  !      A(1:2,INDX(I)), I = 1 to N is sorted,
  !
  !    or explicitly, by the call
  !
  !      call R82VEC_PERMUTE ( N, A, INDX )
  !
  !    after which A(1:2,I), I = 1 to N is sorted.
  !
  !  Modified:
  !
  !    08 December 2004
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer N, the number of entries in the array.
  !
  !    Input, real ( kind = 8 ) A(2,N), an array to be index-sorted.
  !
  !    Output, integer INDX(N), the sort index.  The
  !    I-th element of the sorted array is A(1:2,INDX(I)).
  !
  implicit none

  integer n

  real ( kind = 8 ) a(2,n)
  real ( kind = 8 ) aval(2)
  integer i
  integer indx(n)
  integer indxt
  integer ir
  integer j
  integer l

  if ( n < 1 ) then
     return
  end if

  do i = 1, n
     indx(i) = i
  end do

  if ( n == 1 ) then
     return
  end if

  l = n / 2 + 1
  ir = n

  do

     if ( 1 < l ) then

        l = l - 1
        indxt = indx(l)
        aval(1:2) = a(1:2,indxt)

     else

        indxt = indx(ir)
        aval(1:2) = a(1:2,indxt)
        indx(ir) = indx(1)
        ir = ir - 1

        if ( ir == 1 ) then
           indx(1) = indxt
           exit
        end if

     end if

     i = l
     j = l + l

     do while ( j <= ir )

        if ( j < ir ) then
           if (   a(1,indx(j)) <  a(1,indx(j+1)) .or. &
                ( a(1,indx(j)) == a(1,indx(j+1)) .and. &
                a(2,indx(j)) <  a(2,indx(j+1)) ) ) then
              j = j + 1
           end if
        end if

        if (   aval(1) <  a(1,indx(j)) .or. &
             ( aval(1) == a(1,indx(j)) .and. &
             aval(2) <  a(2,indx(j)) ) ) then
           indx(i) = indx(j)
           i = j
           j = j + j
        else
           j = ir + 1
        end if

     end do

     indx(i) = indxt

  end do

  return
end subroutine r82vec_sort_heap_index_a
subroutine r82vec_sort_quick_a ( n, a )

  !*****************************************************************************80
  !
  !! R82VEC_SORT_QUICK_A ascending sorts an R82VEC using quick sort.
  !
  !  Modified:
  !
  !    08 December 2004
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer N, the number of entries in the array.
  !
  !    Input/output, real ( kind = 8 ) A(2,N).
  !    On input, the array to be sorted.
  !    On output, the array has been sorted.
  !
  implicit none

  integer, parameter :: level_max = 25
  integer n
  integer, parameter :: dim_num = 2

  real ( kind = 8 ) a(dim_num,n)
  integer base
  integer l_segment
  integer level
  integer n_segment
  integer rsave(level_max)
  integer r_segment

  if ( n < 1 ) then
     write ( *, '(a)' ) ' '
     write ( *, '(a)' ) 'R82VEC_SORT_QUICK_A - Fatal error!'
     write ( *, '(a)' ) '  N < 1.'
     stop
  else if ( n == 1 ) then
     return
  end if

  level = 1
  rsave(level) = n + 1
  base = 1
  n_segment = n

  do
     !
     !  Partition the segment.
     !
     call r82vec_part_quick_a ( n_segment, a(1,base), l_segment, r_segment )
     !
     !  If the left segment has more than one element, we need to partition it.
     !
     if ( 1 < l_segment ) then

        if ( level_max < level ) then
           write ( *, '(a)' ) ' '
           write ( *, '(a)' ) 'R82VEC_SORT_QUICK_A - Fatal error!'
           write ( *, '(a,i8)' ) '  Exceeding recursion maximum of ', level_max
           stop
        end if

        level = level + 1
        n_segment = l_segment
        rsave(level) = r_segment + base - 1
        !
        !  The left segment and the middle segment are sorted.
        !  Must the right segment be partitioned?
        !
     else if ( r_segment < n_segment ) then

        n_segment = n_segment + 1 - r_segment
        base = base + r_segment - 1
        !
        !  Otherwise, we back up a level if there is an earlier one.
        !
     else

        do

           if ( level <= 1 ) then
              return
           end if

           base = rsave(level)
           n_segment = rsave(level-1) - rsave(level)
           level = level - 1

           if ( 0 < n_segment ) then
              exit
           end if

        end do

     end if

  end do

  return
end subroutine r82vec_sort_quick_a
subroutine r8mat_transpose_print ( m, n, a, title )

  !*****************************************************************************80
  !
  !! R8MAT_TRANSPOSE_PRINT prints an R8MAT, transposed.
  !
  !  Modified:
  !
  !    14 June 2004
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer M, N, the number of rows and columns.
  !
  !    Input, real ( kind = 8 ) A(M,N), an M by N matrix to be printed.
  !
  !    Input, character ( len = * ) TITLE, an optional title.
  !
  implicit none

  integer m
  integer n

  real ( kind = 8 ) a(m,n)
  character ( len = * ) title

  call r8mat_transpose_print_some ( m, n, a, 1, 1, m, n, title )

  return
end subroutine r8mat_transpose_print
subroutine r8mat_transpose_print_some ( m, n, a, ilo, jlo, ihi, jhi, title )

  !*****************************************************************************80
  !
  !! R8MAT_TRANSPOSE_PRINT_SOME prints some of an R8MAT, transposed.
  !
  !  Modified:
  !
  !    14 June 2004
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer M, N, the number of rows and columns.
  !
  !    Input, real ( kind = 8 ) A(M,N), an M by N matrix to be printed.
  !
  !    Input, integer ILO, JLO, the first row and column to print.
  !
  !    Input, integer IHI, JHI, the last row and column to print.
  !
  !    Input, character ( len = * ) TITLE, an optional title.
  !
  implicit none

  integer, parameter :: incx = 5
  integer m
  integer n

  real ( kind = 8 ) a(m,n)
  character ( len = 14 ) ctemp(incx)
  integer i
  integer i2
  integer i2hi
  integer i2lo
  integer ihi
  integer ilo
  integer inc
  integer j
  integer j2hi
  integer j2lo
  integer jhi
  integer jlo
  character ( len = * ) title

  if ( 0 < len_trim ( title ) ) then
     write ( *, '(a)' ) ' '
     write ( *, '(a)' ) trim ( title )
  end if

  do i2lo = max ( ilo, 1 ), min ( ihi, m ), incx

     i2hi = i2lo + incx - 1
     i2hi = min ( i2hi, m )
     i2hi = min ( i2hi, ihi )

     inc = i2hi + 1 - i2lo

     write ( *, '(a)' ) ' '

     do i = i2lo, i2hi
        i2 = i + 1 - i2lo
        write ( ctemp(i2), '(i7,7x)') i
     end do

     write ( *, '(''  Row   '',5a14)' ) ctemp(1:inc)
     write ( *, '(a)' ) '  Col'
     write ( *, '(a)' ) ' '

     j2lo = max ( jlo, 1 )
     j2hi = min ( jhi, n )

     do j = j2lo, j2hi

        do i2 = 1, inc
           i = i2lo - 1 + i2
           write ( ctemp(i2), '(g14.6)' ) a(i,j)
        end do

        write ( *, '(i5,1x,5a14)' ) j, ( ctemp(i), i = 1, inc )

     end do

  end do

  write ( *, '(a)' ) ' '

  return
end subroutine r8mat_transpose_print_some
subroutine r8mat_uniform ( m, n, a, b, seed, r )

  !*****************************************************************************80
  !
  !! R8MAT_UNIFORM fills an R8MAT with scaled pseudorandom numbers.
  !
  !  Modified:
  !
  !    05 February 2005
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Reference:
  !
  !    Paul Bratley, Bennett Fox, L E Schrage,
  !    A Guide to Simulation,
  !    Springer Verlag, pages 201-202, 1983.
  !
  !    Bennett Fox,
  !    Algorithm 647:
  !    Implementation and Relative Efficiency of Quasirandom
  !    Sequence Generators,
  !    ACM Transactions on Mathematical Software,
  !    Volume 12, Number 4, pages 362-376, 1986.
  !
  !    P A Lewis, A S Goodman, J M Miller,
  !    A Pseudo-Random Number Generator for the System/360,
  !    IBM Systems Journal,
  !    Volume 8, pages 136-143, 1969.
  !
  !  Parameters:
  !
  !    Input, integer M, N, the number of rows and columns in the array.
  !
  !    Input, real ( kind = 8 ) A, B, the lower and upper limits.
  !
  !    Input/output, integer SEED, the "seed" value, which should NOT be 0.
  !    On output, SEED has been updated.
  !
  !    Output, real ( kind = 8 ) R(M,N), the array of pseudorandom values.
  !
  implicit none

  integer m
  integer n

  real ( kind = 8 ) a
  real ( kind = 8 ) b
  integer i
  integer j
  integer k
  integer seed
  real ( kind = 8 ) r(m,n)

  do j = 1, n

     do i = 1, m

        k = seed / 127773

        seed = 16807 * ( seed - k * 127773 ) - k * 2836

        if ( seed < 0 ) then
           seed = seed + 2147483647
        end if

        r(i,j) = a + ( b - a ) * real ( seed, kind = 8 ) * 4.656612875D-10

     end do
  end do

  return
end subroutine r8mat_uniform
function r8vec_eq ( n, a1, a2 )

  !*****************************************************************************80
  !
  !! R8VEC_EQ is true if two R8VEC's are equal.
  !
  !  Modified:
  !
  !    05 December 2004
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer N, the number of entries in the vectors.
  !
  !    Input, real ( kind = 8 ) A1(N), A2(N), two vectors to compare.
  !
  !    Output, logical R8VEC_EQ, is TRUE if every pair of elements A1(I)
  !    and A2(I) are equal, and FALSE otherwise.
  !
  implicit none

  integer n

  real ( kind = 8 ) a1(n)
  real ( kind = 8 ) a2(n)
  logical r8vec_eq

  r8vec_eq = ( all ( a1(1:n) == a2(1:n) ) )

  return
end function r8vec_eq
function r8vec_gt ( n, a1, a2 )

  !*****************************************************************************80
  !
  !! R8VEC_GT == ( A1 > A2 ) for R8VEC's.
  !
  !  Discussion:
  !
  !    The comparison is lexicographic.
  !
  !    A1 > A2  <=>                              A1(1) > A2(1) or
  !                 ( A1(1)     == A2(1)     and A1(2) > A2(2) ) or
  !                 ...
  !                 ( A1(1:N-1) == A2(1:N-1) and A1(N) > A2(N)
  !
  !  Modified:
  !
  !    05 December 2004
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer N, the dimension of the vectors.
  !
  !    Input, real ( kind = 8 ) A1(N), A2(N), the vectors to be compared.
  !
  !    Output, logical R8VEC_GT, is TRUE if and only if A1 > A2.
  !
  implicit none

  integer n

  real ( kind = 8 ) a1(n)
  real ( kind = 8 ) a2(n)
  logical r8vec_gt
  integer i

  r8vec_gt = .false.

  do i = 1, n

     if ( a2(i) < a1(i) ) then
        r8vec_gt = .true.
        exit
     else if ( a1(i) < a2(i) ) then
        r8vec_gt = .false.
        exit
     end if

  end do

  return
end function r8vec_gt
function r8vec_lt ( n, a1, a2 )

  !*****************************************************************************80
  !
  !! R8VEC_LT == ( A1 < A2 ) for R8VEC's.
  !
  !  Discussion:
  !
  !    The comparison is lexicographic.
  !
  !    A1 < A2  <=>                              A1(1) < A2(1) or
  !                 ( A1(1)     == A2(1)     and A1(2) < A2(2) ) or
  !                 ...
  !                 ( A1(1:N-1) == A2(1:N-1) and A1(N) < A2(N)
  !
  !  Modified:
  !
  !    05 December 2004
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer N, the dimension of the vectors.
  !
  !    Input, real ( kind = 8 ) A1(N), A2(N), the vectors to be compared.
  !
  !    Output, logical R8VEC_LT, is TRUE if and only if A1 < A2.
  !
  implicit none

  integer n

  real ( kind = 8 ) a1(n)
  real ( kind = 8 ) a2(n)
  logical r8vec_lt
  integer i

  r8vec_lt = .false.

  do i = 1, n

     if ( a1(i) < a2(i) ) then
        r8vec_lt = .true.
        exit
     else if ( a2(i) < a1(i) ) then
        r8vec_lt = .false.
        exit
     end if

  end do

  return
end function r8vec_lt
subroutine r8vec_print ( n, a, title )

  !*****************************************************************************80
  !
  !! R8VEC_PRINT prints an R8VEC.
  !
  !  Modified:
  !
  !    22 August 2000
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer N, the number of components of the vector.
  !
  !    Input, real ( kind = 8 ) A(N), the vector to be printed.
  !
  !    Input, character ( len = * ) TITLE, an optional title.
  !
  implicit none

  integer n

  real ( kind = 8 ) a(n)
  integer i
  character ( len = * ) title

  if ( 0 < len_trim ( title ) ) then
     write ( *, '(a)' ) ' '
     write ( *, '(a)' ) trim ( title )
  end if

  write ( *, '(a)' ) ' '
  do i = 1, n
     write ( *, '(2x,i8,g16.8)' ) i, a(i)
  end do

  return
end subroutine r8vec_print
subroutine r8vec_swap ( n, a1, a2 )

  !*****************************************************************************80
  !
  !! R8VEC_SWAP swaps the entries of two R8VEC's.
  !
  !  Modified:
  !
  !    04 December 2004
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer N, the number of entries in the arrays.
  !
  !    Input/output, real ( kind = 8 ) A1(N), A2(N), the vectors to swap.
  !
  implicit none

  integer n

  real ( kind = 8 ) a1(n)
  real ( kind = 8 ) a2(n)
  real ( kind = 8 ) a3(n)

  a3(1:n) = a1(1:n)
  a1(1:n) = a2(1:n)
  a2(1:n) = a3(1:n)

  return
end subroutine r8vec_swap
subroutine swapec ( i, top, btri, bedg, node_num, node_xy, triangle_num, &
     triangle_node, triangle_neighbor, stack, ierr )

  !*****************************************************************************80
  !
  !! SWAPEC swaps diagonal edges until all triangles are Delaunay.
  !
  !  Discussion:
  !
  !    The routine swaps diagonal edges in a 2D triangulation, based on
  !    the empty circumcircle criterion, until all triangles are Delaunay,
  !    given that I is the index of the new vertex added to the triangulation.
  !
  !  Modified:
  !
  !    14 July 2001
  !
  !  Author:
  !
  !    Barry Joe,
  !    Department of Computing Science,
  !    University of Alberta,
  !    Edmonton, Alberta, Canada  T6G 2H1
  !
  !  Reference:
  !
  !    Barry Joe,
  !    GEOMPACK - a software package for the generation of meshes
  !    using geometric algorithms,
  !    Advances in Engineering Software,
  !    Volume 13, pages 325-331, 1991.
  !
  !  Parameters:
  !
  !    Input, integer I, the index of the new vertex.
  !
  !    Input/output, integer TOP, the index of the top of the stack.
  !    On output, TOP is zero.
  !
  !    Input/output, integer BTRI, BEDG; on input, if positive, are the
  !    triangle and edge indices of a boundary edge whose updated indices
  !    must be recorded.  On output, these may be updated because of swaps.
  !
  !    Input, integer NODE_NUM, the number of points.
  !
  !    Input, real ( kind = 8 ) NODE_XY(2,NODE_NUM), the coordinates of
  !    the points.
  !
  !    Input, integer TRIANGLE_NUM, the number of triangles.
  !
  !    Input/output, integer TRIANGLE_NODE(3,TRIANGLE_NUM), the triangle 
  !    incidence list.  May be updated on output because of swaps.
  !
  !    Input/output, integer TRIANGLE_NEIGHBOR(3,TRIANGLE_NUM), the triangle
  !    neighbor list; negative values are used for links of the counter-clockwise
  !    linked list of boundary edges;  May be updated on output because of swaps.
  !
  !      LINK = -(3*I + J-1) where I, J = triangle, edge index.
  !
  !    Workspace, integer STACK(MAXST); on input, entries 1 through TOP
  !    contain the indices of initial triangles (involving vertex I)
  !    put in stack; the edges opposite I should be in interior;  entries
  !    TOP+1 through MAXST are used as a stack.
  !
  !    Output, integer IERR is set to 8 for abnormal return.
  !
  implicit none

  integer node_num
  integer triangle_num

  integer a
  integer b
  integer bedg
  integer btri
  integer c
  integer diaedg
  integer e
  integer ee
  integer em1
  integer ep1
  integer f
  integer fm1
  integer fp1
  integer i
  integer ierr
  integer i4_wrap
  integer l
  real ( kind = 8 ) node_xy(2,node_num)
  integer r
  integer s
  integer stack(node_num)
  integer swap
  integer t
  integer top
  integer triangle_neighbor(3,triangle_num)
  integer triangle_node(3,triangle_num)
  integer tt
  integer u
  real ( kind = 8 ) x
  real ( kind = 8 ) y
  !
  !  Determine whether triangles in stack are Delaunay, and swap
  !  diagonal edge of convex quadrilateral if not.
  !
  x = node_xy(1,i)
  y = node_xy(2,i)

  do

     if ( top <= 0 ) then
        exit
     end if

     t = stack(top)
     top = top - 1

     if ( triangle_node(1,t) == i ) then
        e = 2
        b = triangle_node(3,t)
     else if ( triangle_node(2,t) == i ) then
        e = 3
        b = triangle_node(1,t)
     else
        e = 1
        b = triangle_node(2,t)
     end if

     a = triangle_node(e,t)
     u = triangle_neighbor(e,t)

     if ( triangle_neighbor(1,u) == t ) then
        f = 1
        c = triangle_node(3,u)
     else if ( triangle_neighbor(2,u) == t ) then
        f = 2
        c = triangle_node(1,u)
     else
        f = 3
        c = triangle_node(2,u)
     end if

     swap = diaedg ( x, y, node_xy(1,a), node_xy(2,a), node_xy(1,c), &
          node_xy(2,c), node_xy(1,b), node_xy(2,b) )

     if ( swap == 1 ) then

        em1 = i4_wrap ( e - 1, 1, 3 )
        ep1 = i4_wrap ( e + 1, 1, 3 )
        fm1 = i4_wrap ( f - 1, 1, 3 )
        fp1 = i4_wrap ( f + 1, 1, 3 )

        triangle_node(ep1,t) = c
        triangle_node(fp1,u) = i
        r = triangle_neighbor(ep1,t)
        s = triangle_neighbor(fp1,u)
        triangle_neighbor(ep1,t) = u
        triangle_neighbor(fp1,u) = t
        triangle_neighbor(e,t) = s
        triangle_neighbor(f,u) = r

        if ( 0 < triangle_neighbor(fm1,u) ) then
           top = top + 1
           stack(top) = u
        end if

        if ( 0 < s ) then

           if ( triangle_neighbor(1,s) == u ) then
              triangle_neighbor(1,s) = t
           else if ( triangle_neighbor(2,s) == u ) then
              triangle_neighbor(2,s) = t
           else
              triangle_neighbor(3,s) = t
           end if

           top = top + 1

           if ( node_num < top ) then
              ierr = 8
              return
           end if

           stack(top) = t

        else

           if ( u == btri .and. fp1 == bedg ) then
              btri = t
              bedg = e
           end if

           l = - ( 3 * t + e - 1 )
           tt = t
           ee = em1

           do while ( 0 < triangle_neighbor(ee,tt) )

              tt = triangle_neighbor(ee,tt)

              if ( triangle_node(1,tt) == a ) then
                 ee = 3
              else if ( triangle_node(2,tt) == a ) then
                 ee = 1
              else
                 ee = 2
              end if

           end do

           triangle_neighbor(ee,tt) = l

        end if

        if ( 0 < r ) then

           if ( triangle_neighbor(1,r) == t ) then
              triangle_neighbor(1,r) = u
           else if ( triangle_neighbor(2,r) == t ) then
              triangle_neighbor(2,r) = u
           else
              triangle_neighbor(3,r) = u
           end if

        else

           if ( t == btri .and. ep1 == bedg ) then
              btri = u
              bedg = f
           end if

           l = - ( 3 * u + f - 1 )
           tt = u
           ee = fm1

           do while ( 0 < triangle_neighbor(ee,tt) )

              tt = triangle_neighbor(ee,tt)

              if ( triangle_node(1,tt) == b ) then
                 ee = 3
              else if ( triangle_node(2,tt) == b ) then
                 ee = 1
              else
                 ee = 2
              end if

           end do

           triangle_neighbor(ee,tt) = l

        end if

     end if

  end do

  return
end subroutine swapec
subroutine timestamp ( )

  !*****************************************************************************80
  !
  !! TIMESTAMP prints the current YMDHMS date as a time stamp.
  !
  !  Example:
  !
  !    May 31 2001   9:45:54.872 AM
  !
  !  Modified:
  !
  !    15 March 2003
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    None
  !
  implicit none

  character ( len = 40 ) string

  call timestring ( string )

  write ( *, '(a)' ) trim ( string )

  return
end subroutine timestamp
subroutine timestring ( string )

  !*****************************************************************************80
  !
  !! TIMESTRING writes the current YMDHMS date into a string.
  !
  !  Example:
  !
  !    STRING = 'May 31 2001   9:45:54.872 AM'
  !
  !  Modified:
  !
  !    15 March 2003
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Output, character ( len = * ) STRING, contains the date information.
  !    A character length of 40 should always be sufficient.
  !
  implicit none

  character ( len = 8 ) ampm
  integer d
  character ( len = 8 ) date
  integer h
  integer m
  integer mm
  character ( len = 9 ), parameter, dimension(12) :: month = (/ &
       'January  ', 'February ', 'March    ', 'April    ', &
       'May      ', 'June     ', 'July     ', 'August   ', &
       'September', 'October  ', 'November ', 'December ' /)
  integer n
  integer s
  character ( len = * ) string
  character ( len = 10 ) time
  integer values(8)
  integer y
  character ( len = 5 ) zone

  call date_and_time ( date, time, zone, values )

  y = values(1)
  m = values(2)
  d = values(3)
  h = values(5)
  n = values(6)
  s = values(7)
  mm = values(8)

  if ( h < 12 ) then
     ampm = 'AM'
  else if ( h == 12 ) then
     if ( n == 0 .and. s == 0 ) then
        ampm = 'Noon'
     else
        ampm = 'PM'
     end if
  else
     h = h - 12
     if ( h < 12 ) then
        ampm = 'PM'
     else if ( h == 12 ) then
        if ( n == 0 .and. s == 0 ) then
           ampm = 'Midnight'
        else
           ampm = 'AM'
        end if
     end if
  end if

  write ( string, '(a,1x,i2,1x,i4,2x,i2,a1,i2.2,a1,i2.2,a1,i3.3,1x,a)' ) &
       trim ( month(m) ), d, y, h, ':', n, ':', s, '.', mm, trim ( ampm )

  return
end subroutine timestring
subroutine triangle_circumcenter_2d ( t, center )

  !*****************************************************************************80
  !
  !! TRIANGLE_CIRCUMCENTER_2D computes the circumcenter of a triangle in 2D.
  !
  !  Discussion:
  !
  !    The circumcenter of a triangle is the center of the circumcircle, the
  !    circle that passes through the three vertices of the triangle.
  !
  !    The circumcircle contains the triangle, but it is not necessarily the
  !    smallest triangle to do so.
  !
  !    If all angles of the triangle are no greater than 90 degrees, then
  !    the center of the circumscribed circle will lie inside the triangle.
  !    Otherwise, the center will lie outside the circle.
  !
  !    The circumcenter is the intersection of the perpendicular bisectors
  !    of the sides of the triangle.
  !
  !    In geometry, the circumcenter of a triangle is often symbolized by "O".
  !
  !  Modified:
  !
  !    09 February 2005
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, real ( kind = 8 ) T(2,3), the triangle vertices.
  !
  !    Output, real ( kind = 8 ) CENTER(2), the circumcenter of the triangle.
  !
  implicit none

  integer, parameter :: dim_num = 2

  real ( kind = 8 ) asq
  real ( kind = 8 ) bot
  real ( kind = 8 ) center(dim_num)
  real ( kind = 8 ) csq
  real ( kind = 8 ) t(dim_num,3)
  real ( kind = 8 ) top(dim_num)

  asq = ( t(1,2) - t(1,1) )**2 + ( t(2,2) - t(2,1) )**2
  csq = ( t(1,3) - t(1,1) )**2 + ( t(2,3) - t(2,1) )**2

  top(1) =  ( t(2,2) - t(2,1) ) * csq - ( t(2,3) - t(2,1) ) * asq
  top(2) =  ( t(1,2) - t(1,1) ) * csq - ( t(1,3) - t(1,1) ) * asq

  bot  =  ( t(2,2) - t(2,1) ) * ( t(1,3) - t(1,1) ) &
       - ( t(2,3) - t(2,1) ) * ( t(1,2) - t(1,1) )

  center(1:2) = t(1:2,1) + 0.5D+00 * top(1:2) / bot

  return
end subroutine triangle_circumcenter_2d
subroutine triangulation_order3_plot ( file_name, node_num, node_xy, &
     triangle_num, triangle_node, node_show, triangle_show )

  !*****************************************************************************80
  !
  !! TRIANGULATION_ORDER3_PLOT plots a 3-node triangulation of a set of nodes.
  !
  !  Discussion:
  !
  !    The triangulation is most usually a Delaunay triangulation,
  !    but this is not necessary.
  !
  !  Modified:
  !
  !    16 March 2005
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, character ( len = * ) FILE_NAME, the name of the output file.
  !
  !    Input, integer NODE_NUM, the number of nodes.
  !
  !    Input, real ( kind = 8 ) NODE_XY(2,NODE_NUM), the coordinates of the nodes.
  !
  !    Input, integer TRIANGLE_NUM, the number of triangles.
  !
  !    Input, integer TRIANGLE_NODE(3,TRIANGLE_NUM), lists, for each triangle,
  !    the indices of the nodes that form the vertices of the triangle.
  !
  !    Input, integer NODE_SHOW,
  !    0, do not show nodes;
  !    1, show nodes;
  !    2, show nodes and label them.
  !
  !    Input, integer TRIANGLE_SHOW,
  !    0, do not show triangles;
  !    1, show triangles;
  !    2, show triangles and label them.
  !
  !  Local parameters:
  !
  !    Local, integer CIRCLE_SIZE, controls the size of the circles depicting
  !    the nodes.  Currently set to 5.  3 is pretty small, and 1 is
  !    barely visible.
  !
  implicit none

  integer node_num
  integer triangle_num

  real ( kind = 8 ) ave_x
  real ( kind = 8 ) ave_y
  character ( len = 40 ) date_time
  integer, parameter :: circle_size = 5
  integer delta
  integer e
  character ( len = * ) file_name
  integer file_unit
  integer i
  integer i4_wrap
  integer ios
  integer node
  integer node_show
  real ( kind = 8 ) node_xy(2,node_num)
  character ( len = 40 ) string
  integer triangle
  integer triangle_node(3,triangle_num)
  integer triangle_show
  real ( kind = 8 ) x_max
  real ( kind = 8 ) x_min
  integer x_ps
  integer :: x_ps_max = 576
  integer :: x_ps_max_clip = 594
  integer :: x_ps_min = 36
  integer :: x_ps_min_clip = 18
  real ( kind = 8 ) x_scale
  real ( kind = 8 ) y_max
  real ( kind = 8 ) y_min
  integer y_ps
  integer :: y_ps_max = 666
  integer :: y_ps_max_clip = 684
  integer :: y_ps_min = 126
  integer :: y_ps_min_clip = 108
  real ( kind = 8 ) y_scale

  call timestring ( date_time )
  !
  !  We need to do some figuring here, so that we can determine
  !  the range of the data, and hence the height and width
  !  of the piece of paper.
  !
  x_max = maxval ( node_xy(1,1:node_num) )
  x_min = minval ( node_xy(1,1:node_num) )
  x_scale = x_max - x_min

  x_max = x_max + 0.05D+00 * x_scale
  x_min = x_min - 0.05D+00 * x_scale
  x_scale = x_max - x_min

  y_max = maxval ( node_xy(2,1:node_num) )
  y_min = minval ( node_xy(2,1:node_num) )
  y_scale = y_max - y_min

  y_max = y_max + 0.05D+00 * y_scale
  y_min = y_min - 0.05D+00 * y_scale
  y_scale = y_max - y_min

  if ( x_scale < y_scale ) then

     delta = nint ( real ( x_ps_max - x_ps_min, kind = 8 ) &
          * ( y_scale - x_scale ) / ( 2.0D+00 * y_scale ) )

     x_ps_max = x_ps_max - delta
     x_ps_min = x_ps_min + delta

     x_ps_max_clip = x_ps_max_clip - delta
     x_ps_min_clip = x_ps_min_clip + delta

     x_scale = y_scale

  else if ( y_scale < x_scale ) then

     delta = nint ( real ( y_ps_max - y_ps_min, kind = 8 ) &
          * ( x_scale - y_scale ) / ( 2.0D+00 * x_scale ) )

     y_ps_max      = y_ps_max - delta
     y_ps_min      = y_ps_min + delta

     y_ps_max_clip = y_ps_max_clip - delta
     y_ps_min_clip = y_ps_min_clip + delta

     y_scale = x_scale

  end if

  call get_unit ( file_unit )

  open ( unit = file_unit, file = file_name, status = 'replace', &
       iostat = ios )

  if ( ios /= 0 ) then
     write ( *, '(a)' ) ' '
     write ( *, '(a)' ) 'TRIANGULATION_ORDER3_PLOT - Fatal error!'
     write ( *, '(a)' ) '  Can not open output file "', trim ( file_name ), '".'
     return
  end if

  write ( file_unit, '(a)' ) '%!PS-Adobe-3.0 EPSF-3.0'
  write ( file_unit, '(a)' ) '%%Creator: triangulation_order3_plot.f90'
  write ( file_unit, '(a)' ) '%%Title: ' // trim ( file_name )
  write ( file_unit, '(a)' ) '%%CreationDate: ' // trim ( date_time )
  write ( file_unit, '(a)' ) '%%Pages: 1'
  write ( file_unit, '(a,i3,2x,i3,2x,i3,2x,i3)' ) '%%BoundingBox: ', &
       x_ps_min, y_ps_min, x_ps_max, y_ps_max
  write ( file_unit, '(a)' ) '%%Document-Fonts: Times-Roman'
  write ( file_unit, '(a)' ) '%%LanguageLevel: 1'
  write ( file_unit, '(a)' ) '%%EndComments'
  write ( file_unit, '(a)' ) '%%BeginProlog'
  write ( file_unit, '(a)' ) '/inch {72 mul} def'
  write ( file_unit, '(a)' ) '%%EndProlog'
  write ( file_unit, '(a)' ) '%%Page: 1 1'
  write ( file_unit, '(a)' ) 'save'
  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) '%  Set the RGB line color to very light gray.'
  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) '0.900  0.900  0.900 setrgbcolor'
  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) '%  Draw a gray border around the page.'
  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) 'newpath'
  write ( file_unit, '(a,i3,2x,i3,2x,a)' ) '  ', x_ps_min, y_ps_min, ' moveto'
  write ( file_unit, '(a,i3,2x,i3,2x,a)' ) '  ', x_ps_max, y_ps_min, ' lineto'
  write ( file_unit, '(a,i3,2x,i3,2x,a)' ) '  ', x_ps_max, y_ps_max, ' lineto'
  write ( file_unit, '(a,i3,2x,i3,2x,a)' ) '  ', x_ps_min, y_ps_max, ' lineto'
  write ( file_unit, '(a,i3,2x,i3,2x,a)' ) '  ', x_ps_min, y_ps_min, ' lineto'
  write ( file_unit, '(a)' ) 'stroke'
  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) '%  Set the RGB color to black.'
  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) '0.000  0.000  0.000 setrgbcolor'
  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) '%  Set the font and its size.'
  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) '/Times-Roman findfont'
  write ( file_unit, '(a)' ) '0.50 inch scalefont'
  write ( file_unit, '(a)' ) 'setfont'
  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) '%  Print a title.'
  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) '%  210  702  moveto'
  write ( file_unit, '(a)' ) '%  (Triangulation)  show'
  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) '%  Define a clipping polygon.'
  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) 'newpath'
  write ( file_unit, '(a,i3,2x,i3,2x,a)' ) '  ', &
       x_ps_min_clip, y_ps_min_clip, ' moveto'
  write ( file_unit, '(a,i3,2x,i3,2x,a)' ) '  ', &
       x_ps_max_clip, y_ps_min_clip, ' lineto'
  write ( file_unit, '(a,i3,2x,i3,2x,a)' ) '  ', &
       x_ps_max_clip, y_ps_max_clip, ' lineto'
  write ( file_unit, '(a,i3,2x,i3,2x,a)' ) '  ', &
       x_ps_min_clip, y_ps_max_clip, ' lineto'
  write ( file_unit, '(a,i3,2x,i3,2x,a)' ) '  ', &
       x_ps_min_clip, y_ps_min_clip, ' lineto'
  write ( file_unit, '(a)' ) 'clip newpath'
  !
  !  Draw the nodes.
  !
  if ( 1 <= node_show ) then
     write ( file_unit, '(a)' ) '%'
     write ( file_unit, '(a)' ) '%  Draw filled dots at the nodes.'
     write ( file_unit, '(a)' ) '%'
     write ( file_unit, '(a)' ) '%  Set the RGB color to blue.'
     write ( file_unit, '(a)' ) '%'
     write ( file_unit, '(a)' ) '0.000  0.150  0.750 setrgbcolor'
     write ( file_unit, '(a)' ) '%'

     do node = 1, node_num

        x_ps = int ( &
             ( ( x_max - node_xy(1,node)         ) * real ( x_ps_min, kind = 8 )   &
             + (         node_xy(1,node) - x_min ) * real ( x_ps_max, kind = 8 ) ) &
             / ( x_max                   - x_min ) )

        y_ps = int ( &
             ( ( y_max - node_xy(2,node)         ) * real ( y_ps_min, kind = 8 )   &
             + (         node_xy(2,node) - y_min ) * real ( y_ps_max, kind = 8 ) ) &
             / ( y_max                   - y_min ) )

        write ( file_unit, '(a,i4,2x,i4,2x,i4,2x,a)' ) 'newpath ', x_ps, y_ps, &
             circle_size, '0 360 arc closepath fill'

     end do

  end if
  !
  !  Label the nodes.
  !
  if ( 2 <= node_show ) then

     write ( file_unit, '(a)' ) '%'
     write ( file_unit, '(a)' ) '%  Label the nodes:'
     write ( file_unit, '(a)' ) '%'
     write ( file_unit, '(a)' ) '%  Set the RGB color to darker blue.'
     write ( file_unit, '(a)' ) '%'
     write ( file_unit, '(a)' ) '0.000  0.250  0.850 setrgbcolor'
     write ( file_unit, '(a)' ) '/Times-Roman findfont'
     write ( file_unit, '(a)' ) '0.20 inch scalefont'
     write ( file_unit, '(a)' ) 'setfont'
     write ( file_unit, '(a)' ) '%'

     do node = 1, node_num

        x_ps = int ( &
             ( ( x_max - node_xy(1,node)         ) * real ( x_ps_min, kind = 8 )   &
             + (       + node_xy(1,node) - x_min ) * real ( x_ps_max, kind = 8 ) ) &
             / ( x_max                   - x_min ) )

        y_ps = int ( &
             ( ( y_max - node_xy(2,node)         ) * real ( y_ps_min, kind = 8 )   &
             + (         node_xy(2,node) - y_min ) * real ( y_ps_max, kind = 8 ) ) &
             / ( y_max                   - y_min ) )

        write ( string, '(i4)' ) node
        string = adjustl ( string )

        write ( file_unit, '(i4,2x,i4,a)' ) x_ps, y_ps+5, &
             ' moveto (' // trim ( string ) // ') show'

     end do

  end if
  !
  !  Draw the triangles.
  !
  if ( 1 <= triangle_show ) then
     write ( file_unit, '(a)' ) '%'
     write ( file_unit, '(a)' ) '%  Set the RGB color to red.'
     write ( file_unit, '(a)' ) '%'
     write ( file_unit, '(a)' ) '0.900  0.200  0.100 setrgbcolor'
     write ( file_unit, '(a)' ) '%'
     write ( file_unit, '(a)' ) '%  Draw the triangles.'
     write ( file_unit, '(a)' ) '%'

     do triangle = 1, triangle_num

        write ( file_unit, '(a)' ) 'newpath'

        do i = 1, 4

           e = i4_wrap ( i, 1, 3 )

           node = triangle_node(e,triangle)

           x_ps = int ( &
                ( ( x_max - node_xy(1,node)         ) * real ( x_ps_min, kind = 8 )   &
                + (         node_xy(1,node) - x_min ) * real ( x_ps_max, kind = 8 ) ) &
                / ( x_max                   - x_min ) )

           y_ps = int ( &
                ( ( y_max - node_xy(2,node)         ) * real ( y_ps_min, kind = 8 )   &
                + (         node_xy(2,node) - y_min ) * real ( y_ps_max, kind = 8 ) ) &
                / ( y_max                   - y_min ) )

           if ( i == 1 ) then
              write ( file_unit, '(i3,2x,i3,2x,a)' ) x_ps, y_ps, ' moveto'
           else
              write ( file_unit, '(i3,2x,i3,2x,a)' ) x_ps, y_ps, ' lineto'
           end if

        end do

        write ( file_unit, '(a)' ) 'stroke'

     end do

  end if
  !
  !  Label the triangles.
  !
  if ( 2 <= triangle_show ) then

     write ( file_unit, '(a)' ) '%'
     write ( file_unit, '(a)' ) '%  Label the triangles:'
     write ( file_unit, '(a)' ) '%'
     write ( file_unit, '(a)' ) '%  Set the RGB color to darker red.'
     write ( file_unit, '(a)' ) '%'
     write ( file_unit, '(a)' ) '0.950  0.250  0.150 setrgbcolor'
     write ( file_unit, '(a)' ) '/Times-Roman findfont'
     write ( file_unit, '(a)' ) '0.20 inch scalefont'
     write ( file_unit, '(a)' ) 'setfont'
     write ( file_unit, '(a)' ) '%'

     do triangle = 1, triangle_num

        ave_x = 0.0D+00
        ave_y = 0.0D+00

        do i = 1, 3

           node = triangle_node(i,triangle)

           ave_x = ave_x + node_xy(1,node)
           ave_y = ave_y + node_xy(2,node)

        end do

        ave_x = ave_x / 3.0D+00
        ave_y = ave_y / 3.0D+00

        x_ps = int ( &
             ( ( x_max - ave_x         ) * real ( x_ps_min, kind = 8 )   &
             + (       + ave_x - x_min ) * real ( x_ps_max, kind = 8 ) ) &
             / ( x_max         - x_min ) )

        y_ps = int ( &
             ( ( y_max - ave_y         ) * real ( y_ps_min, kind = 8 )   &
             + (         ave_y - y_min ) * real ( y_ps_max, kind = 8 ) ) &
             / ( y_max         - y_min ) )

        write ( string, '(i4)' ) triangle
        string = adjustl ( string )

        write ( file_unit, '(i4,2x,i4,a)' ) x_ps, y_ps, ' moveto (' &
             // trim ( string ) // ') show'

     end do

  end if

  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) 'restore  showpage'
  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) '%  End of page.'
  write ( file_unit, '(a)' ) '%'
  write ( file_unit, '(a)' ) '%%Trailer'
  write ( file_unit, '(a)' ) '%%EOF'
  close ( unit = file_unit )

  return
end subroutine triangulation_order3_plot
subroutine triangulation_order3_print ( node_num, triangle_num, node_xy, &
     triangle_node, triangle_neighbor )

  !*****************************************************************************80
  !
  !! TRIANGULATION_ORDER3_PRINT prints out information defining a Delaunay triangulation.
  !
  !  Discussion:
  !
  !    Triangulations created by DTRIS2 include extra information encoded
  !    in the negative values of TRIANGLE_NEIGHBOR.
  !
  !    Because some of the nodes counted in NODE_NUM may not actually be
  !    used in the triangulation, I needed to compute the true number
  !    of vertices.  I added this calculation on 13 October 2001.
  !
  !  Modified:
  !
  !    26 November 2002
  !
  !  Author:
  !
  !    John Burkardt
  !
  !  Parameters:
  !
  !    Input, integer NODE_NUM, the number of nodes.
  !
  !    Input, integer TRIANGLE_NUM, the number of triangles.
  !
  !    Input, real ( kind = 8 ) NODE_XY(2,NODE_NUM), the coordinates of the nodes.
  !
  !    Input, integer TRIANGLE_NODE(3,TRIANGLE_NUM), the nodes that make up the
  !    triangles.
  !
  !    Input, integer TRIANGLE_NEIGHBOR(3,TRIANGLE_NUM), the triangle neighbors on
  !    each side.  If there is no triangle neighbor on a particular side, the
  !    value of TRIANGLE_NEIGHBOR should be negative.  If the triangulation
  !    data was created by DTRIS2, then there is more information encoded
  !    in the negative values.
  !
  implicit none

  integer, parameter :: dim_num = 2
  integer node_num
  integer triangle_num

  integer boundary_num
  integer i
  integer i4_wrap
  integer j
  integer k
  integer n1
  integer n2
  real ( kind = 8 ) node_xy(dim_num,node_num)
  integer s
  logical skip
  integer t
  integer triangle_node(3,triangle_num)
  integer triangle_neighbor(3,triangle_num)
  integer, allocatable, dimension ( : ) :: vertex_list
  integer vertex_num

  write ( *, '(a)' ) ' '
  write ( *, '(a)' ) 'TRIANGULATION_ORDER3_PRINT'
  write ( *, '(a)' ) '  Information defining an order3 triangulation.'
  write ( *, '(a)' ) ' '
  write ( *, '(a,i8)' ) '  The number of nodes is ', node_num

  call r8mat_transpose_print ( dim_num, node_num, node_xy, '  Node coordinates' )

  write ( *, '(a)' ) ' '
  write ( *, '(a,i8)' ) '  The number of triangles is ', triangle_num
  write ( *, '(a)' ) ' '
  write ( *, '(a)' ) '  Sets of three nodes are used as vertices of'
  write ( *, '(a)' ) '  the triangles.  For each triangle, the nodes'
  write ( *, '(a)' ) '  are listed in counterclockwise order.'

  call i4mat_transpose_print ( 3, triangle_num, triangle_node, &
       '  Triangle nodes:' )

  write ( *, '(a)' ) ' '
  write ( *, '(a)' ) '  On each side of a given triangle, there is either'
  write ( *, '(a)' ) '  another triangle, or a piece of the convex hull.'
  write ( *, '(a)' ) '  For each triangle, we list the indices of the three'
  write ( *, '(a)' ) '  neighbors, or (if negative) the codes of the'
  write ( *, '(a)' ) '  segments of the convex hull.'

  call i4mat_transpose_print ( 3, triangle_num, triangle_neighbor, &
       '  Triangle neighbors' )
  !
  !  Determine the number of vertices.
  !
  allocate ( vertex_list(1:3*triangle_num) )

  vertex_list(1:3*triangle_num) = reshape ( triangle_node(1:3,1:triangle_num), &
       (/ 3*triangle_num /) )

  call i4vec_sort_heap_a ( 3*triangle_num, vertex_list )

  call i4vec_sorted_unique ( 3*triangle_num, vertex_list, vertex_num )

  deallocate ( vertex_list )
  !
  !  Determine the number of boundary points.
  !
  boundary_num = 2 * vertex_num - triangle_num - 2

  write ( *, '(a)' ) ' '
  write ( *, '(a,i8)' ) '  The number of boundary points is ', boundary_num

  write ( *, '(a)' ) ' '
  write ( *, '(a)' ) '  The segments that make up the convex hull can be'
  write ( *, '(a)' ) '  determined from the negative entries of the triangle'
  write ( *, '(a)' ) '  neighbor list.'
  write ( *, '(a)' ) ' '
  write ( *, '(a)' ) '     #   Tri  Side    N1    N2'
  write ( *, '(a)' ) ' '

  skip = .false.

  k = 0

  do i = 1, triangle_num

     do j = 1, 3

        if ( triangle_neighbor(j,i) < 0 ) then
           s = - triangle_neighbor(j,i)
           t = s / 3

           if ( t < 1 .or. triangle_num < t ) then
              write ( *, '(a)' ) ' '
              write ( *, '(a)' ) '  Sorry, this data does not use the DTRIS2'
              write ( *, '(a)' ) '  convention for convex hull segments.'
              skip = .true.
              exit
           end if

           s = mod ( s, 3 ) + 1
           k = k + 1
           n1 = triangle_node(s,t)
           n2 = triangle_node(i4_wrap(s+1,1,3),t)
           write ( *, '(2x,i4,2x,i4,2x,i4,2x,i4,2x,i4)' ) k, t, s, n1, n2
        end if

     end do

     if ( skip ) then
        exit
     end if

  end do

  return
end subroutine triangulation_order3_print
subroutine vbedg ( x, y, node_num, node_xy, triangle_num, triangle_node, &
     triangle_neighbor, ltri, ledg, rtri, redg )

  !*****************************************************************************80
  !
  !! VBEDG determines which boundary edges are visible to a point.
  !
  !  Discussion:
  !
  !    The point (X,Y) is assumed to be outside the convex hull of the
  !    region covered by the 2D triangulation.
  !
  !  Author:
  !
  !    Barry Joe,
  !    Department of Computing Science,
  !    University of Alberta,
  !    Edmonton, Alberta, Canada  T6G 2H1
  !
  !  Reference:
  !
  !    Barry Joe,
  !    GEOMPACK - a software package for the generation of meshes
  !    using geometric algorithms,
  !    Advances in Engineering Software,
  !    Volume 13, pages 325-331, 1991.
  !
  !  Modified:
  !
  !    25 August 2001
  !
  !  Parameters:
  !
  !    Input, real ( kind = 8 ) X, Y, the coordinates of a point outside the
  !    convex hull of the current triangulation.
  !
  !    Input, integer NODE_NUM, the number of points.
  !
  !    Input, real ( kind = 8 ) NODE_XY(2,NODE_NUM), the coordinates of the
  !    vertices.
  !
  !    Input, integer TRIANGLE_NUM, the number of triangles.
  !
  !    Input, integer TRIANGLE_NODE(3,TRIANGLE_NUM), the triangle incidence list.
  !
  !    Input, integer TRIANGLE_NEIGHBOR(3,TRIANGLE_NUM), the triangle neighbor
  !    list; negative values are used for links of a counter clockwise linked
  !    list of boundary edges;
  !      LINK = -(3*I + J-1) where I, J = triangle, edge index.
  !
  !    Input/output, integer LTRI, LEDG.  If LTRI /= 0 then these values are
  !    assumed to be already computed and are not changed, else they are updated.
  !    On output, LTRI is the index of boundary triangle to the left of the
  !    leftmost boundary triangle visible from (X,Y), and LEDG is the boundary
  !    edge of triangle LTRI to the left of the leftmost boundary edge visible
  !    from (X,Y).  1 <= LEDG <= 3.
  !
  !    Input/output, integer RTRI.  On input, the index of the boundary triangle
  !    to begin the search at.  On output, the index of the rightmost boundary
  !    triangle visible from (X,Y).
  !
  !    Input/output, integer REDG, the edge of triangle RTRI that is visible
  !    from (X,Y).  1 <= REDG <= 3.
  !
  implicit none

  integer, parameter :: dim_num = 2
  integer node_num
  integer triangle_num

  integer a
  integer b
  integer e
  integer i4_wrap
  integer l
  logical ldone
  integer ledg
  integer lr
  integer lrline
  integer ltri
  real ( kind = 8 ) node_xy(2,node_num)
  integer redg
  integer rtri
  integer t
  integer triangle_neighbor(3,triangle_num)
  integer triangle_node(3,triangle_num)
  real ( kind = 8 ) x
  real ( kind = 8 ) y
  !
  !  Find the rightmost visible boundary edge using links, then possibly
  !  leftmost visible boundary edge using triangle neighbor information.
  !
  if ( ltri == 0 ) then
     ldone = .false.
     ltri = rtri
     ledg = redg
  else
     ldone = .true.
  end if

  do

     l = -triangle_neighbor(redg,rtri)
     t = l / 3
     e = mod ( l, 3 ) + 1
     a = triangle_node(e,t)

     if ( e <= 2 ) then
        b = triangle_node(e+1,t)
     else
        b = triangle_node(1,t)
     end if

     lr = lrline ( x, y, node_xy(1,a), node_xy(2,a), node_xy(1,b), &
          node_xy(2,b), 0.0D+00 )

     if ( lr <= 0 ) then
        exit
     end if

     rtri = t
     redg = e

  end do

  if ( ldone ) then
     return
  end if

  t = ltri
  e = ledg

  do

     b = triangle_node(e,t)
     e = i4_wrap ( e-1, 1, 3 )

     do while ( 0 < triangle_neighbor(e,t) )

        t = triangle_neighbor(e,t)

        if ( triangle_node(1,t) == b ) then
           e = 3
        else if ( triangle_node(2,t) == b ) then
           e = 1
        else
           e = 2
        end if

     end do

     a = triangle_node(e,t)

     lr = lrline ( x, y, node_xy(1,a), node_xy(2,a), node_xy(1,b), &
          node_xy(2,b), 0.0D+00 )

     if ( lr <= 0 ) then
        exit
     end if

  end do

  ltri = t
  ledg = e

  return
end subroutine vbedg

     	 

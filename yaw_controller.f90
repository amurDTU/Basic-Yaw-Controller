module yaw_mod
   use yaw_controller_fcns
   contains
!**************************************************************************************************
   subroutine init_yaw(array1,array2)
!      use write_version_mod
      implicit none
      !DEC$ IF .NOT. DEFINED(__LINUX__)
      !DEC$ ATTRIBUTES DLLEXPORT, C, ALIAS:'init_yaw'::init_yaw
      !DEC$ END IF
      real(mk) array1(100), array2(1)
      real(mk) ,dimension(yawst%larray) :: arrayaux
      ! Input array1 must contain
      !    1: constant 1 ; Time Start 
      !    2: constant 2 ; Array distance (mean deficit /dt)
      !    3: constant 3 ; Threshold (deg)

      
      yawst%tstart = array1(1)
      yawst%larray = array1(2)
      yawst%threshold = array1(3)
      yawst%memory = array1(4)    
      yawst%larray2 = array1(5) 
      yawst%meancomp = array1(6)
      array2 = 0.0_mk
      yawst%arrayaux(1,1:yawst%larray) = 0.0
      yawst%lastyaw=  0.0
      yawst%ct = 0 
    
      write(0,*) ' Exit init'
   end subroutine init_yaw
!**************************************************************************************************
!**************************************************************************************************
!**************************************************************************************************
   subroutine update_yaw(array1, array2)
      implicit none
      !DEC$ IF .NOT. DEFINED(__LINUX__)
      !DEC$ ATTRIBUTES DLLEXPORT, C, ALIAS:'update_yaw'::update_yaw
      !DEC$ END IF
        real*8 array1(100), array2(100), arrayaux(10000000)
        real*8 :: yaw_cur,time,val ! current yaw angle , time 
        real*8 :: yaw_err, yaw_err2 , lastyaw
        real, DIMENSION(yawst%larray) :: aux_var
        real*8 :: angle_mis
        real*8 :: nac_ang
        real*8 :: yaw_flag, thresholdap, err_memr
        integer :: casesel , mem_alloc , meancomp

        ! ** 3 component for velocity (wind + direction) 
        ! ** Get wind direction based on wind speed (degrees)
        angle_mis = atan(array1(2)/array1(3))*(180/pi)
        ! * Get current nacelle angle 
        nac_ang = array1(5)
        ! * Helps initialization of moving average vector in case wrong settings has been defined 
        ! if moving average is not complete when yawing is done it is completed
        
        
        if (yawst%memory.gt.0)  then 
            mem_alloc = 1
        else
            mem_alloc = 0
        endif
        if (yawst%meancomp.gt.0)  then 
            meancomp = 1
        else
            meancomp = 0
        endif        
        
            
        
         
            if (yawst%flagyaw.eq.0) then                                                         
                    yawst%arrayaux(1,2:yawst%larray) =  yawst%arrayaux(1,1:yawst%larray-1)
                    yawst%arrayaux(1,1) = angle_mis
                    yawst%ct = yawst%ct +1                                                    
        
            !** yaw error is detectec
            elseif (yawst%flagyaw.eq.1) then         
            
                 if (yawst%ct.lt.yawst%larray) then                                          ! if the array has not completed before evaluating yaw, we complete it with the mean
                 !write(0,*) 'Yaw error detected before moving average 1 is completed'
             
            
                 select case(meancomp)                                                       ! select if the moving average 1 is completed with the mean values or not
                 
                 case(0)
                     yawst%arrayaux(1,2:yawst%larray) =  yawst%arrayaux(1,1:yawst%larray-1)
                     yawst%arrayaux(1,1) = angle_mis         
                 !write(0,*) 'The mean error is computed normally'
                 
                 case(1)
                 
                     arrayaux(1:yawst%ct) = yawst%arrayaux(1,1:yawst%ct)
                     err_memr = sum(arrayaux) /yawst%ct            
                     yawst%arrayaux(1,1:yawst%larray) =  err_memr
                     yawst%ct = yawst%larray
                 !write(0,*) 'The mean error is used as initialization of the array'
                 
                 end select
            
                 else
                   yawst%arrayaux(1,2:yawst%larray) =  yawst%arrayaux(1,1:yawst%larray-1)
                   yawst%arrayaux(1,1) = angle_mis            
             
                endif             
            endif   
       
              
        ! compute average mean 
        ! 
       
        aux_var = yawst%arrayaux(1,1:yawst%larray)
        yaw_err = sum(aux_var) / yawst%larray
        yaw_err2 = sum(aux_var(1:yawst%larray2)) / yawst%larray2
        
        
        ! go for lower threshold when yawing / avoid in-out close to stop 
        
        if (yawst%flagyaw.eq.1) then 
            thresholdap = yawst%threshold/2
        else
            thresholdap = yawst%threshold
        endif
        
        
        casesel = 0
        
        
        

        
        if (((array1(1)-yawst%lastyaw).gt.yawst%tstart).and.(abs(yaw_err).gt.thresholdap)) then
            casesel = 1
        endif    
      

        if ((yawst%flagyaw.eq.1).and.(abs(yaw_err2).lt.thresholdap)) then 
            casesel = 2 
        endif
        
                
       

        
        select case (casesel)
        
        case(0)
            
            array2(1) = nac_ang
            yawst%flagyaw =  0    
        
        case (1)
        
            yawst%flagyaw = 1                                                                          ! start yawing 
            array2(1) = 100*yaw_err*(pi/180)                                                           ! we are asking the controller to continue yawing until threshold            
        
        case(2)          
          
             yawst%flagyaw = 0                                                                           ! stop    
             array2(1) = nac_ang
             yawst%lastyaw = array1(1)
            
            select case(mem_alloc)
            
        
            case(0)    
            ! Do nothing ... memory is not erased
            
            case(1)
               
             yawst%arrayaux(1,1:yawst%larray) = 0
             
        end select   
        end select
        
        array2(2) = yaw_err                 ! error first moving average
        array2(3) = yaw_err2                ! error second moving average
        array2(4) = yawst%flagyaw           ! flag yawing
        array2(6) = casesel

   end subroutine update_yaw
!**************************************************************************************************
! *** Interpolate function ***

end module yaw_mod

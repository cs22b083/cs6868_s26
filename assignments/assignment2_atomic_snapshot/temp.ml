                
WARNING: ThreadSanitizer: data race (pid=31242)
  Read of size 8 at 0x00011c803eb8 by thread T14 (mutexes: write M0):
    #0 camlSnapshot$fun_366 <null>:126886480 (test_manual.exe:arm64+0x1000061ec)
    #1 camlStdlib__Array$init_295 <null>:126886480 (test_manual.exe:arm64+0x1000280d0)
    #2 camlSnapshot$loop_347 <null>:126886480 (test_manual.exe:arm64+0x100006308)
    #3 camlDune__exe__Test_manual$fun_529 <null>:126886480 (test_manual.exe:arm64+0x100005738)
    #4 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #5 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #6 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #7 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #8 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Previous write of size 8 at 0x00011c803eb8 by thread T10 (mutexes: write M1):
    #0 caml_modify <null>:126886480 (test_manual.exe:arm64+0x10009ba4c)
    #1 camlSnapshot$update_335 <null>:126886480 (test_manual.exe:arm64+0x1000060d0)
    #2 camlDune__exe__Test_manual$fun_507 <null>:126886480 (test_manual.exe:arm64+0x100005524)
    #3 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #4 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #5 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #6 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #7 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Mutex M0 (0x00010e000338) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Mutex M1 (0x00010e0001f8) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T14 (tid=6542023, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlDune__exe__Test_manual$test_concurrent_scans_418 <null>:126886480 (test_manual.exe:arm64+0x1000050f0)
    #5 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e40)
    #6 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #7 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #8 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #9 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #10 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T10 (tid=6542019, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlDune__exe__Test_manual$test_concurrent_scans_418 <null>:126886480 (test_manual.exe:arm64+0x100005040)
    #5 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e40)
    #6 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #7 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #8 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #9 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #10 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

SUMMARY: ThreadSanitizer: data race (test_manual.exe:arm64+0x1000061ec) in camlSnapshot$fun_366+0x54
==================
==================
WARNING: ThreadSanitizer: data race (pid=31242)
  Read of size 8 at 0x00011c803ee8 by thread T12 (mutexes: write M0):
    #0 camlSnapshot$fun_366 <null>:126886480 (test_manual.exe:arm64+0x1000061ec)
    #1 camlStdlib__Array$init_295 <null>:126886480 (test_manual.exe:arm64+0x10002806c)
    #2 camlSnapshot$loop_347 <null>:126886480 (test_manual.exe:arm64+0x100006308)
    #3 camlDune__exe__Test_manual$fun_522 <null>:126886480 (test_manual.exe:arm64+0x100005648)
    #4 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #5 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #6 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #7 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #8 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Previous write of size 8 at 0x00011c803ee8 by thread T10 (mutexes: write M1):
    #0 caml_modify <null>:126886480 (test_manual.exe:arm64+0x10009ba4c)
    #1 camlSnapshot$update_335 <null>:126886480 (test_manual.exe:arm64+0x1000060d0)
    #2 camlDune__exe__Test_manual$fun_507 <null>:126886480 (test_manual.exe:arm64+0x1000054f8)
    #3 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #4 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #5 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #6 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #7 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Mutex M0 (0x00010e000478) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Mutex M1 (0x00010e0001f8) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T12 (tid=6542021, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlDune__exe__Test_manual$test_concurrent_scans_418 <null>:126886480 (test_manual.exe:arm64+0x100005098)
    #5 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e40)
    #6 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #7 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #8 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #9 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #10 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T10 (tid=6542019, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlDune__exe__Test_manual$test_concurrent_scans_418 <null>:126886480 (test_manual.exe:arm64+0x100005040)
    #5 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e40)
    #6 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #7 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #8 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #9 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #10 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

SUMMARY: ThreadSanitizer: data race (test_manual.exe:arm64+0x1000061ec) in camlSnapshot$fun_366+0x54
==================
==================
WARNING: ThreadSanitizer: data race (pid=31242)
  Read of size 8 at 0x00011c803ea8 by thread T14 (mutexes: write M0):
    #0 camlSnapshot$fun_366 <null>:126886480 (test_manual.exe:arm64+0x1000061ec)
    #1 camlStdlib__Array$init_295 <null>:126886480 (test_manual.exe:arm64+0x1000280d0)
    #2 camlSnapshot$loop_347 <null>:126886480 (test_manual.exe:arm64+0x100006308)
    #3 camlDune__exe__Test_manual$fun_529 <null>:126886480 (test_manual.exe:arm64+0x100005738)
    #4 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #5 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #6 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #7 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #8 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Previous write of size 8 at 0x00011c803ea8 by thread T10 (mutexes: write M1):
    #0 caml_modify <null>:126886480 (test_manual.exe:arm64+0x10009ba4c)
    #1 camlSnapshot$update_335 <null>:126886480 (test_manual.exe:arm64+0x1000060d0)
    #2 camlDune__exe__Test_manual$fun_507 <null>:126886480 (test_manual.exe:arm64+0x100005550)
    #3 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #4 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #5 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #6 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #7 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Mutex M0 (0x00010e000338) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Mutex M1 (0x00010e0001f8) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T14 (tid=6542023, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlDune__exe__Test_manual$test_concurrent_scans_418 <null>:126886480 (test_manual.exe:arm64+0x1000050f0)
    #5 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e40)
    #6 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #7 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #8 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #9 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #10 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T10 (tid=6542019, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlDune__exe__Test_manual$test_concurrent_scans_418 <null>:126886480 (test_manual.exe:arm64+0x100005040)
    #5 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e40)
    #6 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #7 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #8 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #9 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #10 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

SUMMARY: ThreadSanitizer: data race (test_manual.exe:arm64+0x1000061ec) in camlSnapshot$fun_366+0x54
==================
==================
WARNING: ThreadSanitizer: data race (pid=31242)
  Write of size 8 at 0x00010cecbf78 by thread T10 (mutexes: write M0):
    #0 caml_modify <null>:126886480 (test_manual.exe:arm64+0x10009ba4c)
    #1 camlSnapshot$update_335 <null>:126886480 (test_manual.exe:arm64+0x1000060d0)
    #2 camlDune__exe__Test_manual$fun_507 <null>:126886480 (test_manual.exe:arm64+0x1000054f8)
    #3 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #4 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #5 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #6 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #7 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Previous read of size 8 at 0x00010cecbf78 by thread T14 (mutexes: write M1):
    #0 camlSnapshot$fun_366 <null>:126886480 (test_manual.exe:arm64+0x1000061ec)
    #1 camlStdlib__Array$init_295 <null>:126886480 (test_manual.exe:arm64+0x10002806c)
    #2 camlSnapshot$loop_347 <null>:126886480 (test_manual.exe:arm64+0x100006318)
    #3 camlDune__exe__Test_manual$fun_529 <null>:126886480 (test_manual.exe:arm64+0x100005738)
    #4 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #5 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #6 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #7 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #8 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Mutex M0 (0x00010e0001f8) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Mutex M1 (0x00010e000338) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T10 (tid=6542019, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlDune__exe__Test_manual$test_concurrent_scans_418 <null>:126886480 (test_manual.exe:arm64+0x100005040)
    #5 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e40)
    #6 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #7 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #8 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #9 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #10 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T14 (tid=6542023, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlDune__exe__Test_manual$test_concurrent_scans_418 <null>:126886480 (test_manual.exe:arm64+0x1000050f0)
    #5 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e40)
    #6 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #7 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #8 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #9 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #10 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

SUMMARY: ThreadSanitizer: data race (test_manual.exe:arm64+0x10009ba4c) in caml_modify+0x38
==================
==================
WARNING: ThreadSanitizer: data race (pid=31242)
  Write of size 8 at 0x00010cecbf68 by thread T10 (mutexes: write M0):
    #0 caml_modify <null>:126886480 (test_manual.exe:arm64+0x10009ba4c)
    #1 camlSnapshot$update_335 <null>:126886480 (test_manual.exe:arm64+0x1000060d0)
    #2 camlDune__exe__Test_manual$fun_507 <null>:126886480 (test_manual.exe:arm64+0x100005524)
    #3 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #4 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #5 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #6 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #7 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Previous read of size 8 at 0x00010cecbf68 by thread T14 (mutexes: write M1):
    #0 camlSnapshot$fun_366 <null>:126886480 (test_manual.exe:arm64+0x1000061ec)
    #1 camlStdlib__Array$init_295 <null>:126886480 (test_manual.exe:arm64+0x1000280d0)
    #2 camlSnapshot$loop_347 <null>:126886480 (test_manual.exe:arm64+0x100006318)
    #3 camlDune__exe__Test_manual$fun_529 <null>:126886480 (test_manual.exe:arm64+0x100005738)
    #4 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #5 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #6 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #7 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #8 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Mutex M0 (0x00010e0001f8) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Mutex M1 (0x00010e000338) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T10 (tid=6542019, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlDune__exe__Test_manual$test_concurrent_scans_418 <null>:126886480 (test_manual.exe:arm64+0x100005040)
    #5 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e40)
    #6 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #7 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #8 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #9 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #10 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T14 (tid=6542023, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlDune__exe__Test_manual$test_concurrent_scans_418 <null>:126886480 (test_manual.exe:arm64+0x1000050f0)
    #5 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e40)
    #6 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #7 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #8 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #9 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #10 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

SUMMARY: ThreadSanitizer: data race (test_manual.exe:arm64+0x10009ba4c) in caml_modify+0x38
==================
==================
WARNING: ThreadSanitizer: data race (pid=31242)
  Write of size 8 at 0x00010cecbf58 by thread T10 (mutexes: write M0):
    #0 caml_modify <null>:126886480 (test_manual.exe:arm64+0x10009ba4c)
    #1 camlSnapshot$update_335 <null>:126886480 (test_manual.exe:arm64+0x1000060d0)
    #2 camlDune__exe__Test_manual$fun_507 <null>:126886480 (test_manual.exe:arm64+0x100005550)
    #3 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #4 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #5 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #6 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #7 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Previous read of size 8 at 0x00010cecbf58 by thread T14 (mutexes: write M1):
    #0 camlSnapshot$fun_366 <null>:126886480 (test_manual.exe:arm64+0x1000061ec)
    #1 camlStdlib__Array$init_295 <null>:126886480 (test_manual.exe:arm64+0x1000280d0)
    #2 camlSnapshot$loop_347 <null>:126886480 (test_manual.exe:arm64+0x100006318)
    #3 camlDune__exe__Test_manual$fun_529 <null>:126886480 (test_manual.exe:arm64+0x100005738)
    #4 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #5 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #6 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #7 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #8 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Mutex M0 (0x00010e0001f8) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Mutex M1 (0x00010e000338) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T10 (tid=6542019, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlDune__exe__Test_manual$test_concurrent_scans_418 <null>:126886480 (test_manual.exe:arm64+0x100005040)
    #5 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e40)
    #6 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #7 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #8 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #9 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #10 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T14 (tid=6542023, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlDune__exe__Test_manual$test_concurrent_scans_418 <null>:126886480 (test_manual.exe:arm64+0x1000050f0)
    #5 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e40)
    #6 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #7 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #8 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #9 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #10 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

SUMMARY: ThreadSanitizer: data race (test_manual.exe:arm64+0x10009ba4c) in caml_modify+0x38
==================
==================
WARNING: ThreadSanitizer: data race (pid=31242)
  Write of size 8 at 0x000104df3de8 by thread T24 (mutexes: write M0):
    #0 caml_modify <null>:126886480 (test_manual.exe:arm64+0x10009ba4c)
    #1 camlSnapshot$update_335 <null>:126886480 (test_manual.exe:arm64+0x1000060d0)
    #2 camlDune__exe__Test_manual$fun_565 <null>:126886480 (test_manual.exe:arm64+0x100005c4c)
    #3 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #4 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #5 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #6 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #7 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Previous read of size 8 at 0x000104df3de8 by thread T22 (mutexes: write M1):
    #0 camlSnapshot$fun_366 <null>:126886480 (test_manual.exe:arm64+0x1000061ec)
    #1 camlStdlib__Array$init_295 <null>:126886480 (test_manual.exe:arm64+0x1000280d0)
    #2 camlSnapshot$loop_347 <null>:126886480 (test_manual.exe:arm64+0x100006308)
    #3 camlDune__exe__Test_manual$fun_565 <null>:126886480 (test_manual.exe:arm64+0x100005cec)
    #4 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #5 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #6 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #7 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #8 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Mutex M0 (0x00010e0001f8) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Mutex M1 (0x00010e000478) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T24 (tid=6542053, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlStdlib__Array$init_295 <null>:126886480 (test_manual.exe:arm64+0x1000280d0)
    #5 camlDune__exe__Test_manual$test_right_contention_447 <null>:126886480 (test_manual.exe:arm64+0x100005a10)
    #6 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e48)
    #7 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #8 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #9 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #10 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #11 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T22 (tid=6542051, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlStdlib__Array$init_295 <null>:126886480 (test_manual.exe:arm64+0x1000280d0)
    #5 camlDune__exe__Test_manual$test_right_contention_447 <null>:126886480 (test_manual.exe:arm64+0x100005a10)
    #6 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e48)
    #7 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #8 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #9 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #10 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #11 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

SUMMARY: ThreadSanitizer: data race (test_manual.exe:arm64+0x10009ba4c) in caml_modify+0x38
==================
==================
WARNING: ThreadSanitizer: data race (pid=31242)
  Write of size 8 at 0x000104df3e18 by thread T24 (mutexes: write M0):
    #0 caml_modify <null>:126886480 (test_manual.exe:arm64+0x10009ba4c)
    #1 camlSnapshot$update_335 <null>:126886480 (test_manual.exe:arm64+0x1000060d0)
    #2 camlDune__exe__Test_manual$fun_565 <null>:126886480 (test_manual.exe:arm64+0x100005c4c)
    #3 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #4 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #5 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #6 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #7 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Previous read of size 8 at 0x000104df3e18 by thread T22 (mutexes: write M1):
    #0 camlSnapshot$fun_366 <null>:126886480 (test_manual.exe:arm64+0x1000061ec)
    #1 camlStdlib__Array$init_295 <null>:126886480 (test_manual.exe:arm64+0x10002806c)
    #2 camlSnapshot$loop_347 <null>:126886480 (test_manual.exe:arm64+0x100006308)
    #3 camlDune__exe__Test_manual$fun_565 <null>:126886480 (test_manual.exe:arm64+0x100005cec)
    #4 camlStdlib__Domain$body_757 <null>:126886480 (test_manual.exe:arm64+0x100046618)
    #5 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #6 caml_callback_exn <null>:126886480 (test_manual.exe:arm64+0x100072944)
    #7 caml_callback_res <null>:126886480 (test_manual.exe:arm64+0x100073294)
    #8 domain_thread_func <null>:126886480 (test_manual.exe:arm64+0x10007704c)

  Mutex M0 (0x00010e0001f8) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Mutex M1 (0x00010e000478) created at:
    #0 pthread_mutex_init <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x3181c)
    #1 caml_plat_mutex_init <null>:126886480 (test_manual.exe:arm64+0x1000a724c)
    #2 caml_init_domains <null>:126886480 (test_manual.exe:arm64+0x100076230)
    #3 caml_init_gc <null>:126886480 (test_manual.exe:arm64+0x100086b80)
    #4 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000ba94c)
    #5 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #6 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T24 (tid=6542053, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlStdlib__Array$init_295 <null>:126886480 (test_manual.exe:arm64+0x1000280d0)
    #5 camlDune__exe__Test_manual$test_right_contention_447 <null>:126886480 (test_manual.exe:arm64+0x100005a10)
    #6 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e48)
    #7 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #8 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #9 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #10 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #11 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

  Thread T22 (tid=6542051, running) created by main thread at:
    #0 pthread_create <null>:125835952 (libclang_rt.tsan_osx_dynamic.dylib:arm64e+0x309d8)
    #1 caml_domain_spawn <null>:126886480 (test_manual.exe:arm64+0x100076cb4)
    #2 caml_c_call <null>:126886480 (test_manual.exe:arm64+0x1000bbb68)
    #3 camlStdlib__Domain$spawn_752 <null>:126886480 (test_manual.exe:arm64+0x100046528)
    #4 camlStdlib__Array$init_295 <null>:126886480 (test_manual.exe:arm64+0x1000280d0)
    #5 camlDune__exe__Test_manual$test_right_contention_447 <null>:126886480 (test_manual.exe:arm64+0x100005a10)
    #6 camlDune__exe__Test_manual$entry <null>:126886480 (test_manual.exe:arm64+0x100005e48)
    #7 caml_program <null>:126886480 (test_manual.exe:arm64+0x100001548)
    #8 caml_start_program <null>:126886480 (test_manual.exe:arm64+0x1000bbd08)
    #9 caml_startup_common <null>:126886480 (test_manual.exe:arm64+0x1000baa50)
    #10 caml_main <null>:126886480 (test_manual.exe:arm64+0x1000bab28)
    #11 main <null>:126886480 (test_manual.exe:arm64+0x100095e10)

SUMMARY: ThreadSanitizer: data race (test_manual.exe:arm64+0x10009ba4c) in caml_modify+0x38
==================
All manual tests passed!
ThreadSanitizer: reported 8 warnings
zsh: abort      dune exec ./test_manual.exe
kadamrohan@Rohans-MacBook-Air-2 assignment2_atomic_snapshot % 
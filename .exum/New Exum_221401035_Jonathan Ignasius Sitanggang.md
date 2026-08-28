
FORM PENGAJUAN JUDUL

Nama	:  Jonathan Ignasius Sitanggang
NIM	:  221401035
Judul diajukan oleh*	:	Dosen Mahasiswa
Bidang Ilmu (tulis dua bidang)	:
Uji Kelayakan Judul**	:   Diterima	   Ditolak Hasil Uji Kelayakan Judul :










Calon Dosen Pembimbing I:
Dr. Jos Timanta Tarigan, S.Kom., M.Sc
198501262015041001

Calon Dosen Pembimbing II:
Herriyance S.T., M.Kom.
198010242010121002


	Medan,
	Ka. Laboratorium Computer Vision dan Multimedia
	



* Centang salah satu atau keduanya	Dr. Pauzi Ibrahim Nainggolan S.Komp., M.Sc.
** Pilih salah satu	198809142020011001

RINGKASAN JUDUL YANG DIAJUKAN

Judul / Topik Skripsi	Implementasi Mekanika Permainan Multiplayer pada Aplikasi Edukasi Super English
Latar Belakang dan Penelitian Terdahulu	Permainan multiplayer telah berkembang menjadi salah satu bentuk hiburan sekaligus sarana interaksi sosial yang sangat diminati. Multiplayer bisa dilakukan dengan teman atau dengan pemain lain yang tidak saling kenal, hal ini memberikan rasa persaingan dan sekaligus rasa kebersamaan yang lebih menarik dibandingkan bermain individu. Permainan multiplayer tidak hanya sekadar media hiburan, tetapi juga berpotensi sebagai media pembelajaran yang interaktif.

Mekanika permainan adalah elemen dasar yang menentukan bagaimana pemain berinteraksi dengan permainan, mekanika mencakup aturan, system, dan alur. Mekanika dirancang agar permainan dapat berfungsi dan menjadi lebih baik, lalu mekanika juga mengembangkan keterlibatan dan pengalaman bermain yang menyenangkan.

Algoritma yang digunakan adalah Game Loop Algorithm, algoritma perulangan permainan merupakan inti penting untuk sebuah game, sebuah pola (pattern) yang memastikan game berjalan secara real-time, terus memperbarui logika permainan dan merender tampilan secara berulang sampai game selesai. Proses ini dilakukan dalam sebuah loop (siklus) sehingga game terasa real-time dan responsif, di mana loop hanya berhenti ketika kondisi akhir tercapai, misalnya pemain keluar dari game atau game over. 
 

Salah satu konsep yang diterapkan dalam pengembangan permainan ini adalah gamifikasi (gamification), yaitu strategi yang menggunakan mekanisme permainan untuk meningkatkan motivasi, keterlibatan, dan pencapaian pengguna. Gamifikasi juga melakukan penerapan elemen-elemen permainan seperti poin, lencana, leaderboard, level, tantangan, dan sistem hadiah (rewarding system). Gamifikasi terbukti mampu meningkatkan motivasi, keterlibatan antar pemain, dan retensi pengguna dalam aktivitas pembelajaran. 

Rewarding system adalah elemen inti dalam gamifikasi yang berperan dalam menjaga keterlibatan pemain. Hadiah dapat berupa poin, lencana, level, maupun power-up yang memengaruhi situasi permainan. Namun, perancangan sistem ini harus memperhatikan keseimbangan antara motivasi untuk belajar dan motivasi untuk hadiah. Dengan kurangnya perancangan yang tepat, pemain dapat mengalami overjustification effect, artinya menurunnya motivasi belajar akibat ketergantungan berlebihan pada hadiah.

Konsep selanjutnya adalah Compulsion loop, yaitu pola desain yang membuat pemain terus kembali bermain dengan menciptakan siklus Trigger  → Action → Reward → Anticipation → Repeat. Ini adalah salah satu konsep inti dari game design, dan biasanya digunakan untuk meningkatkan retensi pemain. 
•	Trigger: Sesuatu yang mendorong pemain untuk bertindak. 
•	Action: Pemain melakukan suatu tindakan dalam game. 
•	Reward: Pemain diberi imbalan atas aksinya. 
•	Anticipation: Pemain membuat komitmen untuk masa depan.
•	Repeat: Siklus diulang, memperkuat kebiasaan.

Dalam multiplayer permainan edukasi, rewarding system dapat diaplikasikan dengan mekanika permainan. Contoh, selain pemberian skor atas jawaban benar, pemain juga bisa memperoleh power-up untuk menghambat lawan atau mempercepat gameplay mereka. Hal ini menciptakan dinamika persaingan yang lebih menarik dan menuntut strategi, sehingga meningkatkan replay value dan keterlibatan sosial antar pemain.

Super English, merupakan aplikasi kuis bahasa Inggris yang akan dikembangkan dengan fitur multiplayer player-versus-player (PVP). Permainan ini memiliki system skor dan waktu, Super English memiliki beberapa game mode, seperti scramble, fill the missing, dan seterusnya. Implementasi fitur multiplayer memungkinkan pemain untuk berkompetisi secara real-time, menambah dimensi sosial, dan memperkuat daya tarik aplikasi.  
   

Super English menerapkan Game Loop Algorithm, dimana tiap input akan memberikan update dan akan dioutputkan sebagai render, seperti saat pemain menekan tombol play (mulai), aplikasi akan melakukan proses update dan hasilnya akan dioutputkan dengan menganti scene menjadi tampilan saat play. Semua aksi akan memberikan feedback dan akan berulang lagi, semua pola itu merupakan game loop algorithm. Algoritma selesai jika pemain menekan tombol quit (keluar).

Saya akan mengembangkan Permainan Super English dengan implementasi mekanika permainan multiplayer pada Super English. Mekanika akan ditambakan sesuai dengan konsep teori Gamifikasi yaitu pemberian Power-up yang meningkatkan intensitas permainan, Power-up bisa di dapat saat pemain melakukan kegiatan tertentu seperti menjawab benar tiga kali berturut-turut atau menyelesaikan quick time event. Power-up yang diperoleh pemain dapat berfungsi untuk meningkatkan performa pemain atau menurunkan performa pemain lain, contoh power up seperti meningkatkan score acquirement saat menjawab benar, memperpanjang waktu individu, menyembunyikan salah satu pilihan pemain lain, memberikan efek atau getaran layar ke pemain lain, dan seterusnya.

Konsep teori gamifikasi permainan selanjutnya yaitu pemberian nilai dalam bentuk skor dengan memerhatikan aspek-aspek tertentu, seperti kecepatan menjawab, jumlah salah, atau penggunaan power-up. Lalu permainan akan memiliki Leaderboard, dimana pemain dapat melihat pemain yang mendapat skor tertinggi, permainan juga memiliki badge, yang dimana badge bisa diproleh saat pemain melakukan hal yang bagus sebagai penghargaan seperti mendapatkan nilai sempurna pada kuis, atau dapat menjawab masing-masing pertanyaan hanya dalam lima detik dengan persentase benar 80%. Hal ini dapat mendorong nilai kompetitif dan engagement para pemain.

Konsep teori selanjutnya adalah Compulsion loop, yaitu pola desain yang membuat pemain terus kembali bermain dengan menciptakan siklus Trigger → Action → Reward → Anticipation → Repeat. Konsep ini akan diimplementasikan ke permainan Super English, Compulsion loop sebagai berikut: 
•	Trigger: Daily quest dengan hadiah (contoh: win with at least 70% score today with game currency as reward)
•	Action: Pilihan tipe game (Word Scramble, Synonyms, Fill words, etc.) 
•	Reward: EXP & Game Currency
•	Anticipation: Beberapa kosmetik di toko yang dapat dibeli menggunakan Game Currency
•	Repeat: Siklus diulang, memperkuat kebiasaan.
  
Fokus penelitian ini sangat relevan dengan Game Development. Algoritma Game Loop sangat berperan penting dalam aplikasi edukasi Super English. Terutama kedua konsep teoritis yaitu: konsep gamifikasi dan konsep compulsion loop, konsep-konsep ini sangat berperan penting dalam implementasi mekanika permainan dan pengembangan aplikasi permainan Super English yang baik.

Judul penelitian terdahulu:
- “Revealing the Theoretical Basis of Gamification: A systematic review and analysis of theory in research on gamification, serious games and game-based learning.”
Pengelompokan teori-teori gamifikasi ke dalam tiga fokus utama: motivasi, perilaku, dan pembelajaran, kemudian menyintesisnya menjadi prinsip-prinsip dasar gamifikasi, seperti pentingnya tujuan yang jelas, umpan balik langsung, penguatan positif, penyesuaian tingkat kesulitan, dan elemen sosial.

- “Virtual Gaming, Actual Damage: Video Game Design That Intentionally and Successfully Addicts Users”
Bagaimana video game developer secara sengaja merancang permainan yang memicu kecanduan melalui teknik psikologi perilaku seperti variable reward schedules dan compulsion loops, yang dapat menyebabkan permainan dimainkan secara berulang-ulang. 

- “Game Loop: The Heart of the Game Engine”
Penelitian ini membahas konsep game loop sebagai komponen inti dari game engine, yang bertugas mengatur alur permainan dengan menangani input, memperbarui state game, dan merender grafis secara berulang hingga game selesai. Pemahaman yang baik tentang game loop penting bagi pengembang untuk menciptakan pengalaman bermain yang menarik.

- “The Application of Game Mechanics and Technological Trend in Game-Based Learning: A Review of the Research”
Penelitian ini merupakan tinjauan sistematis terhadap 30 penelitian terkait game-based learning (GBL) dari 2012–2022. Hasil kajian menunjukkan bahwa penerapan mekanisme permainan, Feedback Model, Incentive & Achievement Model, dan Progression Model, secara signifikan meningkatkan keterlibatan siswa, dengan 12 penelitian menggunakan ketiganya sekaligus. Tren terbaru menunjukkan penggunaan platform berbasis web semakin dominan, diikuti desktop dan mobile, serta meningkatnya fitur online yang mendukung fleksibilitas belajar.
Rumusan Masalah	1.	Bagaimana merancang dan mengimplementasikan mekanika permainan multiplayer PVP (player versus player) pada permainan edukasi Super English agar dapat berjalan secara real-time dan memberikan pengalaman kompetisi yang menarik?
2.	Bagaimana penerapan konsep Gamifikasi yaitu point, badge, leaderboard (PBL), reward, challenge, and level dapat meningkatkan keterlibatan pemain dalam konteks game edukasi berbasis multiplayer Super English?
3.	Bagaimana penerapan konsep Compulsion loop yaitu Trigger → Action → Reward → Anticipation → Repeat dapat meningkatkan replayability dalam permainan Super English?
Metodologi Penelitian	Tahap awal :
-	Studi literatur mengenai mekanika permainan, Game Loop Algorithm, konsep gamifikasi, konsep Compulsion loop, educational game, multiplayer, Power-up, dan referensi penelitian lainnya.
-	Analisis kebutuhan sistem, termasuk fitur Super English yang akan dikembangkan dengan mode multiplayer PVP.
Tahap perancangan :
-	Desain mekanika permainan, termasuk mode PVP, aturan permainan, dan alur interaksi antar pemain dengan pola Game Loop Algorithm.
-	Perancangan Mekanika Permainan konsep Gamifikasi (point, badge, leaderboard (PBL), reward, challenge, and level) untuk permainan Super English.
-	Perancangan Mekanika Permainan konsep Compulsion loop (Trigger → Action → Reward → Anticipation → Repeat) untuk permainan Super English.
-	Perancangan antarmuka pengguna (user interface) Super English
Tahap implementasi :
-	Implementasi Konsep Gamifikasi dan Compulsion loop ke permainan Super English.
-	Pembangunan antarmuka (user interface) dan logika aturan permainan sesuai dengan perancangan.
-	Pengembangan database untuk menyimpan data pemain, skor, dan riwayat permainan.
Tahap pengujian :
-	Memeriksa apakah alur permainan berjalan dengan baik.
-	Memeriksa apakah semua implementasi sudah diterapkan dengan benar. 
-	Menguji kestabilan koneksi multiplayer, latency, serta sinkronisasi data antar pemain.
-	Melibatkan sejumlah pengguna untuk mencoba aplikasi dan memberikan tanggapan terkait permainan.
Tahap evaluasi :
-	Analisis hasil pengujian untuk mengidentifikasi kelebihan dan kekurangan implementasi mekanika permainan.
-	Evaluasi efektivitas implementasi mekanika permainan.
-	Evaluasi pengaruh konsep Gamifikasi dan Compulsion loop terhadap pemain. 
-	Penyusunan kesimpulan dan saran.
Referensi	[1] Hamari, J., Koivisto, J., & Sarsa, H. (2014). Does gamification work?  A literature review of empirical studies on gamification. 47th Hawaii International Conference on System Sciences, 3025–3034. https://doi.org/10.1109/HICSS.2014.377
[2] Mileff, P. (2023). Game loop: The heart of the game engine. Production Systems and Information Engineering, 11(3), 51–63. https://doi.org/10.32968/psaie.2023.3.4
[3] Mekler, E. D., Brühlmann, F., Tuch, A. N., & Opwis, K. (2017). Towards understanding the effects of individual gamification elements on intrinsic motivation and performance. Computers in Human Behavior, 71, 525–534. https://doi.org/10.1016/j.chb.2015.08.048
[4] Xu, B., & Chen, N. (2020). The Impact of Leaderboards and Reward Systems on Player Engagement in Educational Games. 2020 IEEE Conference on Games (CoG), 257–264. https://doi.org/10.1109/CoG47356.2020.9231804
[5] Riyandi, M. A. O., Santoso, H. B., & Putra, P. O. H. (2023). The application of game mechanics and technological trend in game-based learning: A review of the research. Jurnal RESTI (Rekayasa Sistem dan Teknologi Informasi), 7(4), 774–781. https://doi.org/10.29207/resti.v7i4.4928 
[6] Su, Y., & Cheng, C. (2022). Designing power-up mechanics for engagement in multiplayer educational games. Proceedings of the 2022 ACM Conference on Human Factors in Computing Systems (CHI 2022). https://doi.org/10.1145/3491102.3517577
[7] Wang, H., & Sun, C.-T. (2011). Game reward systems: Gaming experiences and social meanings. Proceedings of DiGRA 2011 Conference: Think Design Play. Digital Games Research Association (DiGRA). http://www.digra.org/digital-library/publications/game-reward-systems-gaming-experiences-and-social-meanings
[8] Krath, J., Schürmann, L., & von Korflesch, H. F. O. (2021). Revealing the theoretical basis of gamification. Computers in Human Behavior, 125, 106963. https://doi.org/10.1016/j.chb.2021.106963

Medan,
Mahasiswa yang mengajukan,



Jonathan Ignasius Sitanggang
221401035
